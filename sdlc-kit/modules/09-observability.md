# Observability

---

## The Three Sigils of Observability

A system is observable if and only if all three signals are present and correlated.

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Logs     │    │   Metrics   │    │   Traces    │
│  (Events)   │    │ (Counters)  │    │  (Spans)    │
├─────────────┤    ├─────────────┤    ├─────────────┤
│ ELK / Loki  │    │ Prometheus  │    │ OpenTeleme- │
│ Structured  │    │  + Grafana  │    │ try + Jaeger│
│ JSON only   │    │ Business    │    │ Distributed │
│ + traceID   │    │ KPI + SLO   │    │  tracing    │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## 1. Logs

### Tools
- **Shipping:** Fluentd / Filebeat → **Elasticsearch** (legacy) or **Loki** (cloud-native, preferred).
- **Storage:** Elasticsearch or Loki (Grafana Cloud / self-hosted).
- **Viewing:** Kibana or Grafana Explore.

### Log Format — Structured JSON Only

No unstructured `print()` or `System.out.println()`. Every log entry **must** be structured JSON.

```json
{
  "timestamp": "2026-06-07T10:30:00.123Z",
  "level": "ERROR",
  "logger": "com.example.application.OrderService",
  "message": "Payment declined during order creation",
  "traceId": "abc123def456",
  "spanId": "span789",
  "service": "order-service",
  "environment": "production",
  "correlationId": "req-001",
  "context": {
    "orderId": "ord-999",
    "customerId": "cust-555",
    "paymentMethod": "credit_card",
    "declineReason": "insufficient_funds"
  }
}
```

### Logging Levels

| Level | When to Use | Volume Target |
|-------|------------|---------------|
| `ERROR` | Operation failed, needs human attention | < 0.1% of total logs |
| `WARN` | Something unexpected but handled gracefully | < 1% |
| `INFO` | Notable lifecycle events (order created, user registered) | ~ 5% |
| `DEBUG` | Development/troubleshooting only — never in production | 0% in prod |
| `TRACE` | Deep debug — never in production | 0% |

### Rules
- Every log line **must** carry a `traceId` (correlated with distributed tracing).
- **Never log PII** (emails, phone numbers, credit cards, passwords).
- Use a **structured logger** (Logback + Logstash encoder for Kotlin, `structlog` for Python).
- Log at the **boundary**: controller (incoming request) and service (result/failure), not inside every line of business logic.

---

## 2. Metrics

### Tools
- **Collection:** Prometheus (pull).
- **Visualization:** Grafana dashboards.
- **Alerting:** AlertManager.

### Types of Metrics

| Metric Type | When to Use | Example |
|-------------|-------------|---------|
| **Counter** | Events that only increase | `http_requests_total{status="200"}` |
| **Gauge** | Values that go up and down | `active_connections`, `queue_depth` |
| **Histogram** | Distribution of latencies | `http_request_duration_seconds` |
| **Summary** | Quantile-based latency | `grpc_server_handling_seconds` |

### Business KPIs (Must Have)

Every production service exposes these business metrics:

```prometheus
# RED Metrics (Rate, Errors, Duration)
http_requests_total{service="order", method="POST", status="2xx"}
http_requests_total{service="order", method="POST", status="5xx"}
http_request_duration_seconds{service="order", quantile="0.99"}

# USE Metrics (Utilization, Saturation, Errors — for infra)
jvm_memory_used_bytes
jvm_thread_states
db_connection_pool_active

# Business KPIs
orders_created_total
orders_cancelled_total
revenue_total{currency="USD"}
```

### SLO Targets

| Signal | Target | Measurement Window |
|--------|--------|-------------------|
| Availability (HTTP 2xx) | ≥ 99.9% | 30 days |
| Latency p99 | ≤ 500ms | 30 days |
| Error rate | ≤ 0.1% of requests | 30 days |
| Integration (async) delay | ≤ 5 seconds p99 | 7 days |

### Alerting Rules

```yaml
# prometheus-rules.yaml
groups:
  - name: order-service
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
        for: 5m
        annotations:
          summary: "Error rate above 1% for 5 minutes"
```

---

## 3. Traces

### Tools
- **Instrumentation:** OpenTelemetry SDK (auto-instrumentation preferred).
- **Backend:** Jaeger or Grafana Tempo.
- **Propagation:** W3C TraceContext (`traceparent` header).

### Tracing Rules

1. **Every request gets a trace.** Auto-instrumentation covers web frameworks, database calls, messaging.
2. **Manual spans** for business-critical operations:

```kotlin
// Kotlin — OpenTelemetry manual span
val span = tracer.spanBuilder("order.create").startSpan()
span.setAttribute("order.id", orderId.toString())
span.setAttribute("total", total.toPlainString())

try {
    // business logic
    span.setStatus(StatusCode.OK)
} catch (e: Exception) {
    span.recordException(e)
    span.setStatus(StatusCode.ERROR)
    throw e
} finally {
    span.end()
}
```

3. **Baggage** — propagate correlation IDs (but keep baggage small; < 10 items).
4. **Sampling:**
   - Production: 100% for error traces, 1–5% for successful requests (head-based).
   - Staging: 100%.

---

## Incident Response

### Flow

```
Detect → Classify → Escalate → Debug → Resolve → Postmortem
```

| Phase | Action | Tool / Artifact |
|-------|--------|----------------|
| **Detect** | Alert fires from AlertManager | AlertManager + PagerDuty / Slack |
| **Classify** | Determine severity | P0 / P1 / P2 (see below) |
| **Escalate** | Notify the right channel | Slack channel: #incident-P0 | Phone call for P0 |
| **Debug** | Find root cause | `traceId=<id>` into logs + Grafana dashboard |
| **Resolve** | Rollback / hotfix / feature flag | Git revert or feature flag toggle |
| **Postmortem** | Write the report | Timeline + 5-Whys + Action Items |

### Severity Classification

| Severity | Definition | Response Time | Escalation |
|----------|-----------|---------------|------------|
| **P0** | Service down for all users, data corruption, security breach | ≤ 15 min | Phone call to on-call + incident commander |
| **P1** | Major feature degraded, partial outage, > 5% error rate | ≤ 30 min | Slack #incident channel + on-call lead |
| **P2** | Minor feature issue, single user, cosmetic | ≤ 4 hours | Slack notification, next sprint |

### Debugging — Trace-First

```
1. Get traceId from the user/customer report or error alert
2. Search logs: grep "traceId=<id>" → find the failing span
3. Open Jaeger/Tempo: inspect full trace for latency or error spans
4. Check dashboard: is error rate elevated? Which endpoint?
5. Check metrics: memory, CPU, DB connection pool
```

---

## Postmortem

**Blameless, written within 48 hours of resolution.**

### Template

```markdown
# Postmortem — [Date] — [Incident Title]

**Severity:** P0
**Duration:** 2026-06-07 14:23 UTC → 14:58 UTC (35 min)
**Impact:** 100% of checkout requests failed. ~1,200 customers affected.

## Timeline (UTC)
- 14:23 — AlertManager fires: checkout error rate > 5%
- 14:25 — On-call acknowledges (Slack)
- 14:28 — `traceId` search reveals `NullPointerException` in PaymentGateway
- 14:32 — Identified: new deployment at 14:00 introduced a null ref in `charge()`
- 14:35 — Rollback triggered
- 14:45 — Rollback complete
- 14:58 — Error rate back to 0%, monitoring green

## 5 Whys
1. Why did checkout fail? → NPE in PaymentGateway.charge()
2. Why was NPE introduced? → New payment method enum value not handled.
3. Why wasn't it caught? → No test for the new enum value.
4. Why was the test missing? → PR review missed the test gap.
5. Why did the deploy go through without catching it? → No integration test for that payment method.

## Action Items
| # | Action | Owner | Issue | Due |
|---|--------|-------|-------|-----|
| 1 | Add test for all PaymentMethod enum values | Alice | #1023 | Sprint 23 |
| 2 | Add integration test for `charge()` with each gateway | Bob | #1024 | Sprint 23 |
| 3 | Add pre-deploy canary that runs 5 test transactions | Carol | #1025 | Sprint 24 |

## What Went Well
- Alert fired within 2 minutes of error rate increase.
- Rollback completed in 10 minutes.

## What Could Be Improved
- No canary deployment before full rollout.
- Missing 5-whys should have been caught in code review.
```