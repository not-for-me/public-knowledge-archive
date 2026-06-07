# SDLC Harness — Software Engineering Guidelines

SDLC skills are auto-discovered by Codex (`~/.agents/skills/`) and Claude Code (`~/.claude/skills/`).
Use `@mention` (Claude) or subagent spawn + skill activate (Codex) to invoke domain expertise.

## Available Skills

| Skill | Domain | Description |
|-------|--------|-------------|
| `sdlc-kit-architect` | 설계 / 아키텍처 | C4 modeling, ADRs, tech selection, system design |
| `sdlc-kit-kotlin-expert` | Kotlin | Idiomatic Kotlin, null safety, coroutines, sealed types |
| `sdlc-kit-spring-expert` | Spring | DI patterns, configuration, testing, security |
| `sdlc-kit-python-expert` | Python | Pythonic idioms, type hints, composition |
| `sdlc-kit-frontend-expert` | Frontend | Component architecture, state management, a11y, perf |
| `sdlc-kit-tdd-expert` | TDD | RED-GREEN-REFACTOR cycle, testing strategy |
| `sdlc-kit-database-expert` | 데이터 | Schema design, query optimization, migration |
| `sdlc-kit-api-designer` | API 설계 | REST/GraphQL/gRPC, versioning, contract evolution |
| `sdlc-kit-devops-expert` | DevOps / Observability | CI/CD, Docker, monitoring, incident response |
| `sdlc-kit-security-reviewer` | 보안 | OWASP Top 10, secret scanning, vulnerability assessment |
| `sdlc-kit-challenger` | 비판적 검토 | Blind spot detection, assumption challenge, cross-skill reference |
| `sdlc-kit-core` | Clean Code / Git | Always-on coding standards (always loaded) |

## Modules (Deep Reference)

Detailed SDLC phase documentation in `modules/`:

| File | Topic |
|------|-------|
| `modules/01-design.md` | Design methodology & ADR templates |
| `modules/02-architecture.md` | Architecture patterns & tech selection deep dive |
| `modules/03-programming-kotlin.md` | Kotlin advanced idioms & patterns |
| `modules/04-programming-python.md` | Python advanced patterns |
| `modules/05-testing-tdd.md` | TDD deep reference |
| `modules/06-clean-code.md` | Clean code extended reference |
| `modules/07-security.md` | Security deep reference |
| `modules/08-devops.md` | DevOps practices deep reference |
| `modules/09-observability.md` | Observability patterns deep reference |

## How Skills Activate

| Tool | Mechanism |
|------|-----------|
| **Codex** | Auto-discovered in `~/.agents/skills/`. Activate via subagent TOML (`skills.config`) or implicit matching |
| **Claude Code** | Auto-discovered in `~/.claude/skills/`. Invoke via `@sdlc-kit-architect` or implicit description matching |
| **Both** | `sdlc-kit-core` loads always (clean code + git conventions); domain skills load on demand only |