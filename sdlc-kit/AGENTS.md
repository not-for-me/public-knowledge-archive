# Software Engineering Guidelines

## 설계 (Design)
ADR(Architecture Decision Records)로 결정을 문서화. C4 모델로 시스템 구조화. 변경 전에 설계 검토.
상세: `@architect` 호출 또는 `modules/01-design.md` 참고.

## 아키텍처 (Architecture)
기술 선정 기준과 패턴. MySQL(트랜잭션/RDBMS), MongoDB(유연스키마), Kafka(이벤트소싱/스트림), Elasticsearch(검색/로그), Neo4j(그래프).
상세: `@architect` 호출 또는 `modules/02-architecture.md` 참고.

## Kotlin
Kotlin idioms: null safety, sealed types, immutability, structured concurrency. Clean architecture — domain 순수 Kotlin 유지.
상세: `@kotlin-expert` 호출 또는 `modules/03-programming-kotlin.md` 참고.

## Spring
Spring Framework & Boot: DI 패턴, 구성 관리, 트랜잭션, 테스팅, Security, REST API 구조. 스프링 방식의 모범 사례와 안티패턴 리뷰.
상세: `@spring-expert` 호출 참고.

## Frontend
Component architecture, state management, 렌더링 성능, 접근성(a11y), 번들 최적화. 프레임워크 독립적인 프론트엔드 모범 사례.
상세: `@frontend-expert` 호출 참고.

## Python
Pythonic idioms: Zen of Python, 명시적 타입힌트, composition over inheritance, EAFP vs LBYL.
상세: `@python-expert` 호출 또는 `modules/04-programming-python.md` 참고.

## TDD (Test-Driven Development)
RED(실패테스트) → GREEN(최소코드) → REFACTOR. Small/Medium/Large 테스트 계층. Testcontainers로 통합테스트. `Thread.sleep()` 금지.
상세: `@tdd-expert` 호출 또는 `modules/05-testing-tdd.md` 참고.

## 데이터 (Database)
Schema 설계, query 최적화, index 전략, migration, storage 선정. 정규화 vs 비정규화 트레이드오프.
상세: `@database-expert` 호출 참고.

## API 설계
RESTful 리소스 모델링, GraphQL 스키마, gRPC/Protobuf, 버저닝 전략, 호환성, 에러 모델.
상세: `@api-designer` 호출 참고.

## Clean Code
함수는 한가지 일, 20줄 이하. Early return, Command-Query Separation. Boolean은 `is/has` 접두사. 생성자 주입만. 주석은 Why만.
상세: `rules/06-clean-code.md` 또는 `modules/06-clean-code.md` 참고.

## 보안 리뷰 (Security)
Pre-commit 시크릿 스캔. SQL/NoSQL Injection, XSS, IDOR, 인증/인가 체크리스트. OWASP Dependency-Check.
상세: `@security-reviewer` 호출 또는 `modules/07-security.md` 참고.

## DevOps
Multi-stage Docker, Trunk-Based Development, Semantic Versioning. PR: lint→type→test→build. Merge: staging→E2E→production.
상세: `@devops-expert` 호출 또는 `modules/08-devops.md` 참고.

## Observability
3 Sigils: 로그(ELK/Loki, JSON+traceID), 메트릭(Prometheus+Grafana), 트레이스(OpenTelemetry+Jaeger). 장애대응: 감지→분류→에스컬레이션→디버깅→Postmortem.
상세: `@devops-expert` 호출 또는 `modules/09-observability.md` 참고.