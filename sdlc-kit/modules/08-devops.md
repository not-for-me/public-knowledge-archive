# DevOps

---

## CI Pipeline — Ordered Stages

Every commit pushed to a feature branch triggers the pipeline. Stages are **strictly ordered** — a stage must pass before the next begins.

```
┌──────┐    ┌──────┐    ┌──────┐    ┌───────┐    ┌──────────────────┐
│ Lint │ →  │ Type │ →  │ Test │ →  │ Build │ →  │ Integration Test │
└──────┘    └──────┘    └──────┘    └───────┘    └──────────────────┘
```

| Stage | Tool | Gate |
|-------|------|------|
| **Lint** | `ktlint` / `detekt` (Kotlin), `ruff` (Python) | Zero errors. All warnings must be justified. |
| **Type** | `kotlinc` / `mypy --strict` | Zero type errors. |
| **Test** | JUnit 5 / pytest (unit + integration) | 100% pass. Coverage: unit ≥ 90%, integration ≥ 80%. |
| **Build** | `./gradlew build` / `uv build` | Artifacts produced. No Gradle/Maven errors. |
| **Integration Test** | Testcontainers on CI | Full Testcontainers suite passes. |

---

## Merge Pipeline — Environment Promotion

```
                    ┌──────────┐      ┌──────────────┐      ┌──────────┐
 feature/*  ───────→│ Staging  │ ────→│   E2E Tests  │ ────→│   Prod   │
                    └──────────┘      └──────────────┘      └──────────┘
                        ↑                    ↑                    ↑
                    merge to            automated            approval +
                    staging             gate                 deploy
```

| Step | Action | Gating |
|------|--------|--------|
| **Feature → Staging** | Merge PR after CI + code review | 2 approvals, all CI checks green |
| **Staging → E2E** | Automated deploy to staging | E2E suite passes (Playwright / RestAssured) |
| **E2E → Prod** | Manual approval by SRE lead | Monitoring dashboards green, canary check passes |

### Rules
- **No direct pushes to `staging` or `main`** — all changes through PRs.
- **E2E tests run on staging against the merged artifact**, not on feature branches.
- **Prod deploy is manual** — requires `approval` from at least one SRE or lead developer.
- **Rollback** within 15 minutes if error rate increases by >1% after deploy.

---

## Docker — Multi-Stage Builds

### Spring Boot (Kotlin)

```dockerfile
# ---- Build Stage ----
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY gradle gradle
COPY build.gradle.kts settings.gradle.kts gradlew ./
COPY src src
RUN ./gradlew bootJar -x test

# ---- Run Stage ----
FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app
ARG JAR_FILE
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Python (FastAPI)

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen

FROM gcr.io/distroless/python3-debian12:nonroot
WORKDIR /app
COPY --from=builder /app /app
COPY src src
EXPOSE 8000
USER nonroot:nonroot
ENTRYPOINT ["python", "-m", "uvicorn", "src.api.routes:app", "--host", "0.0.0.0"]
```

### Base Image Rules
- **Production:** Use `distroless` or `alpine` (or `wolfi`). Never `ubuntu` or `debian:latest`.
- **Development:** Use `-slim` or `-alpine` variants.
- **No `:latest` tags** — pin to a digest or specific version.

### Spring Boot Layered JAR

```dockerfile
# Leverage Spring Boot's built-in layer support
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY build/libs/*.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app
COPY --from=builder dependencies/ ./
COPY --from=builder spring-boot-loader/ ./
COPY --from=builder snapshot-dependencies/ ./
COPY --from=builder application/ ./
USER nonroot:nonroot
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```

**Why layered JAR?** Changes to application code do not invalidate the Docker layer cache for dependencies. Build time drops from 5 min to 30 seconds.

---

## Trunk-Based Development

| Branch | Purpose | Lifetime | Source |
|--------|---------|----------|--------|
| `main` (or `staging`) | Integration branch | Permanent | PRs from feature branches |
| `fix/order-validation` | Bug fix | ≤ 2 days | `main` |
| `feat/payment-v2` | Feature | ≤ 5 days | `main` |
| `release/v2.1.0` | Release preparation | ≤ 1 day | `main` |

### Rules
- **Short-lived branches** — feature branches live ≤ 5 days. Fix branches ≤ 2 days.
- **Rebase, don't merge** — rebase feature branches onto `main` before opening a PR.
- **No `develop` branch** — trunk-based means one long-lived branch (or `staging` and `main`).
- **Feature flags** — incomplete features are hidden behind feature flags, not branches.

---

## Semantic Versioning

```
v{major}.{minor}.{patch}
```

| Component | Bump When |
|-----------|-----------|
| **Major** | Breaking API change, incompatible database migration, removed endpoint/field |
| **Minor** | New feature, new endpoint, backward-compatible addition |
| **Patch** | Bug fix, security patch, internal refactoring with no API change |

### Tagging

```bash
git tag -a v2.1.0 -m "Release v2.1.0 — Add payment reconciliation endpoint"
git push origin v2.1.0
```

- Every release **must** be tagged with a signed git tag.
- Tags are created **after** the merge to `main` and before the deploy.
- Version is auto-incremented by CI (e.g. `git cliff` or semantic-release tool).

---

## Branch Naming Convention

```
{prefix}/{description}
```

| Prefix | Use |
|--------|-----|
| `fix/` | Bug fixes |
| `feat/` | New features |
| `chore/` | Dependency upgrades, tooling, CI changes |
| `docs/` | Documentation only |
| `refactor/` | Code restructuring with no behavior change |

### Examples

```
fix/order-validation-npe
feat/payment-v2-reconciliation
chore/upgrade-spring-boot-3.3
docs/add-adr-for-kafka-topics
refactor/extract-order-domain-service
```

### Branch Name Rules
- Lowercase only. Hyphens, not underscores or slashes beyond the prefix.
- No ticket numbers in the branch name (they go in the PR title and commit messages).
- Branch name ≤ 50 characters.