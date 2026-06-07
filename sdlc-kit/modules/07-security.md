# Security

---

## Pre-Commit Checks

Every commit is checked for secrets and sensitive files before reaching the remote.

### Secrets Scanning

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.0
    hooks:
      - id: trufflehog
```

### .gitignore Verification

The `.gitignore` **must** include at minimum:

```gitignore
.env
.env.*
*.pem
*.key
*.p12
*.jks
*.cer
*.crt
secrets.*
credentials.*
service-account.*
**/terraform.tfstate*
```

**Rule:** Any PR that adds a new secret file type must also update `.gitignore`. No `.env` file is ever committed — use `.env.example` with placeholder values.

---

## SQL Injection Prevention

| ORM / Tool | Risky Pattern | Safe Pattern |
|-----------|--------------|-------------|
| **MyBatis** | `${columnName}` (string substitution) | `#{value}` (parameterized) |
| **JPA / Hibernate** | `@Query("...where name = '"+name+"'")` | `@Query("...where name = :name")` + `@Param("name")` |
| **JDBC** | `Statement.executeQuery(sql)` | `PreparedStatement` with `?` placeholders |
| **JOOQ** | Raw string concatenation | DSL API only |

### Hard Rules
- **Never** concatenate user input into SQL strings.
- **Never** use MyBatis `${}` with user-supplied data.
- **Never** bypass JPA criteria API for dynamic queries — use `Specification` or `Querydsl`.
- All dynamic sorting/filtering must use a whitelist approach:

```kotlin
// ✅ Safe — whitelist
val allowedSortFields = setOf("createdAt", "status", "total")
if (sortBy !in allowedSortFields) throw ValidationException("Invalid sort field")
```

---

## Cross-Site Scripting (XSS)

### Input Sanitization

- `@RequestBody` deserialization is **not** sanitized by default.
- Use a **dedicated sanitizer** at the controller boundary:

```kotlin
// Controller boundary — sanitize before passing to application service
@PostMapping
fun createReview(@RequestBody @Valid request: CreateReviewRequest): ReviewResponse {
    val sanitized = request.copy(
        content = HtmlSanitizer.sanitize(request.content)
    )
    return service.createReview(sanitized.toCommand())
}
```

```python
# FastAPI middleware or dependency
from markupsafe import escape

def sanitize_html(text: str) -> str:
    return escape(text)
```

### Output Encoding
- **Templates:** Use auto-escaping (e.g. Thymeleaf `th:text`, Jinja2 autoescape).
- **REST APIs:** Return JSON only (no HTML in response bodies).
- **Headers:** Set `Content-Type: application/json` and `X-Content-Type-Options: nosniff`.

---

## Authentication & Authorization Checklist

Every endpoint — including health checks, unless explicitly excluded — **must** be authenticated.

| Check | Rule |
|-------|------|
| **All endpoints authenticated** | Public endpoints (login, register, health) are explicitly listed in security config. Everything else requires a valid token. |
| **RBAC** | Roles are assigned at deployment, not in code. Use role hierarchy: `VIEWER < EDITOR < ADMIN`. |
| **JWT** | Use **RS256** or **ES256** (asymmetric). Never `HS256` with public secret. |
| **JWT expiry** | Access token ≤ 15 minutes. Refresh token ≤ 7 days (rotate on use). |
| **Rate limiting** | Per-IP: 100 req/min for anonymous, 1000 req/min for authenticated. Critical endpoints (login, password reset): 5 req/min. |
| **Password policy** | Min 12 chars, hashed with bcrypt (cost ≥ 12) or Argon2id. |

### JWT Validation Rules

```kotlin
// Must verify on every request:
// 1. Signature (using public key, rotated every 90 days)
// 2. Expiration (iat, exp)
// 3. Issuer (iss == our service)
// 4. Audience (aud == this service name)
// 5. Not blacklisted (check against token blacklist for immediate revocation)
```

---

## Data Protection

| Layer | Requirement |
|-------|------------|
| **At rest** | TLS 1.3 for all database connections. AES-256 for encrypting PII columns at database level. |
| **In transit** | TLS 1.3 for all service-to-service communication (mTLS for internal cluster traffic). |
| **Log masking** | Credit cards, SSNs, passwords, tokens, and PII are masked before logging: `4111****1111`. |
| **IDOR prevention** | Never trust client-supplied IDs. Always verify ownership: `order.userId == currentUser.id`. |

### IDOR Check Pattern

```kotlin
// ✅ Secure — verify ownership
fun getOrder(orderId: UUID, currentUser: User): Order {
    val order = orderRepository.findById(orderId)
        ?: throw NotFoundException("Order not found")
    if (order.customerId != currentUser.id) {
        throw ForbiddenException("You do not own this order")
    }
    return order
}
```

---

## File Upload Security

```yaml
# application.yml — Spring Boot
spring:
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB
```

| Check | Rule |
|-------|------|
| **Size limit** | 10 MB hard cap. Compress images server-side for thumbnails. |
| **Extension whitelist** | Only allow: `.pdf`, `.jpg`, `.jpeg`, `.png`, `.gif`, `.csv`, `.xlsx`. Block `.exe`, `.bat`, `.sh`, `.jar`, `.zip`, `.html`. |
| **Path traversal** | Strip `../` and absolute paths. Store files with UUID filenames: `{uuid}.{ext}`. Never use user-provided filenames. |
| **Content-type verification** | Validate MIME type server-side, not just the extension. |

---

## Dependency Vulnerability Scanning

```yaml
# OWASP Dependency-Check — Gradle plugin
plugins {
    id("org.owasp.dependencycheck") version "9.0.9"
}

dependencyCheck {
    failBuildOnCVSS = 7.0  // fail on High and Critical
    suppressionFile = "dependency-check-suppressions.xml"  // approved exceptions only
}
```

- **Every CI build** runs dependency-check.
- **CVSS ≥ 7.0** → build fails. Fix within 1 sprint.
- **CVSS ≥ 9.0** → build fails. Fix within 48 hours or rollback the dependency.
- **Suppressions** require a written justification and expiry date in the suppressions file.