# Architecture

> Reference: *Software Architecture: The Hard Parts* 2nd Edition, Chapters 9–19

---

## Technology Selection Criteria

Every technology choice **must** be justified against the table below. If a tech is used outside its "when to use" column, an ADR is required.

### Data Stores

| Technology | When to Use | When NOT to Use |
|-----------|-------------|----------------|
| **MySQL / PostgreSQL** | Relational data with ACID requirements; structured query patterns; joins across entities; reporting/BI. | Unstructured blobs; high-velocity time-series; graph traversal as primary access pattern. |
| **MongoDB** | Flexible/evolving schema; document-oriented aggregates; high write throughput; geo-spatial queries; no joins needed. | Strict relational integrity (foreign keys, multi-record transactions at scale); complex multi-entity reporting. |
| **Apache Kafka** | Event-driven architecture; stream processing; decoupled async communication; audit log / event sourcing; data pipeline backbone. | Request-response RPC; low-latency (<10ms) synchronous calls; simple queue with one consumer. |
| **Elasticsearch** | Full-text search; log analytics; observability dashboards; fuzzy/autocomplete queries. | Primary data store (no strong consistency, no transactions); CRUD-heavy workloads. |
| **Neo4j** | Graph traversal (recommendations, fraud detection, social networks, dependency trees); path-finding queries that are O(n²) in SQL. | Simple CRUD with tabular data; high-volume write-only workloads; already-well-served by relational schema. |

### Selection Process

1. **Profile the access patterns** — write 3–5 concrete queries before choosing.
2. **Test with realistic data volume** — a PoC must run against data ≥ 50% of expected production size.
3. **Re-evaluate at every major version upgrade** — the landscape changes (e.g. PostgreSQL JSONB vs MongoDB).

---

## Kafka Topic Naming Convention

```
<domain>.<event-name>.<version>
```

- **domain** — bounded context or microservice name (singular, lowercase, hyphenated).
- **event-name** — past-tense verb describing what happened.
- **version** — `v1`, `v2`, etc. Bump on incompatible schema changes.

### Examples

| Topic | Meaning |
|-------|---------|
| `order.placed.v1` | An order was placed (initial schema) |
| `payment.authorized.v2` | A payment was authorized (v2, e.g. added currency field) |
| `inventory.reserved.v1` | Inventory was reserved for an order |
| `user.registered.v1` | A user registered |

### Rules
- **Never reuse a topic name** for a different schema — always bump the version.
- **Consumers** must tolerate both old and new versions for at least one release cycle.
- **Schema Registry** (Avro / Protobuf) is mandatory for any topic with >1 consumer.
- **Topic count** should stay under 100 per cluster; above that, consider grouping or splitting domains.

---

## Infrastructure as Code (IaC) with Terraform

All cloud infrastructure **must** be defined in Terraform, **committed to git**, and applied through CI/CD.

### Repository Structure

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
└── modules/
    ├── networking/
    ├── compute/
    ├── database/
    └── monitoring/
```

### Rules

1. **State** — stored in remote backend (S3 + DynamoDB locking). Never commit `terraform.tfstate` to git.
2. **Modules** — every reusable piece (VPC, ECS cluster, RDS instance) is a module. No inline resources in environments/.
3. **No manual changes** — if a resource is created/modified outside Terraform, it must be imported and the drift resolved within the same sprint.
4. **`terraform plan`** is required in every PR that modifies `.tf` files. Fail the build if plan shows unexpected changes.
5. **Workspaces** are for environments only. Use `-var-file=environments/<env>/terraform.tfvars`.
6. **Pre-commit hooks** — `terraform fmt -recursive` and `terraform validate` on every commit.

### Security

- Secrets (DB passwords, API keys) are injected via **vault** or **AWS Secrets Manager** — never in `.tfvars`.
- IAM policies follow least-privilege. One Terraform module = one IAM role.

---

## Architecture Governance

From *SW Architecture 2nd Ed Ch9–19*:

| Principle | Rule |
|-----------|------|
| **Coupling** | Services should share data through events, not direct calls. Sync calls only for queries that must be real-time. |
| **Cohesion** | A service owns its data. No shared databases across bounded contexts. |
| **Consistency** | Prefer eventual consistency across services. Use Sagas (Choreography) for multi-step workflows. |
| **Evolution** | New integration pattern → write an ADR. Every 6 months, review all ADRs and mark deprecated endpoints/topics. |