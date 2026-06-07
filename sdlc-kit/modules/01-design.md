# Design

> Reference: *Software Architecture: The Hard Parts* 2nd Edition, Chapter 21

---

## Architecture Decision Records (ADR)

Every significant architectural decision **must** be documented as an ADR. The file is stored in `docs/adr/NNNN-title.md` and follows this template:

```markdown
# NNNN — Title

**Status:** [Proposed | Accepted | Deprecated | Superseded]

**Date:** YYYY-MM-DD

## Context
Why is this decision needed? What forces, constraints, or trade-offs are at play?
Include relevant background, assumptions, and alternatives considered.

## Decision
What was decided? State the chosen option clearly and concisely.
This is the "what" — not the "how".

## Consequences
- **Positive:** What becomes easier, faster, or safer?
- **Negative:** What is sacrificed or made harder?
- **Neutral:** What other changes or decisions does this enable or block?
```

### ADR Rules
1. **One decision per ADR** — if two decisions are coupled, write two ADRs with cross-references.
2. **Status transitions** — Accepted → Deprecated → Superseded. Never delete an ADR.
3. **Superseding** ADR must reference the old ADR number in its Context section.
4. **Rejected alternatives** are listed in Context, not Decision.

---

## C4 Model for Software Architecture

All system documentation **must** use C4 levels. Diagrams live in `docs/diagrams/` (use Structurizr DSL or PlantUML).

| Level | Name | Audience | Scope |
|-------|------|----------|-------|
| **C1** | System Context | Non-technical stakeholders | One system box, users, external systems |
| **C2** | Container | Dev team, ops | Services, databases, message queues |
| **C3** | Component | Developers | Inside one container — classes, modules |
| **C4** | Code | Developers | Individual classes (IDE-level; usually omitted) |

### C4 Rules
- C1 diagram is mandatory for every project.
- C2 is required before any implementation begins.
- C3 is required for any container with >3 components.
- C4 is optional — link to generated API docs instead.
- Every element in a C4 diagram has a **Technology** tag (e.g. `[Container: API Gateway: Spring Cloud Gateway]`).

---

## Design Antipatterns

Three antipatterns from *Software Architecture 2nd Ed Ch21* that must be actively gated against:

### 1. Covering Your Assets (CYA)
**Symptom:** Design reviews stall because architects/developers refuse to make a decision without "more data."

**Fix:**
- Set a **decision deadline** with a named decider.
- Use the **Last Responsible Moment** principle (see below).
- Frame decisions as reversible/irreversible. Most decisions are reversible and should be made quickly.

### 2. Groundhog Day
**Symptom:** The same design discussion recurs every sprint because the decision was never written down or a trade-off wasn't captured.

**Fix:**
- Write an ADR (see above) for every resolved dispute.
- Include the *rejected alternatives* and *why they were rejected*.
- Close the conversation with a named ADR issue/PR.

### 3. Email-Driven Architecture
**Symptom:** Critical architectural decisions and rationales live in Slack threads, email chains, or meeting notes instead of the repo.

**Fix:**
- **No architecture decision is valid unless it's in an ADR in git.**
- Code review gates: any PR that introduces a new dependency, framework, or integration point must link to an ADR.
- Use ADR issue templates in your project board.

---

## Last Responsible Moment (LRM)

> "Make decisions at the last responsible moment — the moment at which delaying a decision increases the cost of change more than making the decision early." — *Software Architecture 2nd Ed*

### How to Apply

1. **Classify decisions:**
   - **Reversible** — cost to undo is low. Make these early, don't overthink.
   - **Irreversible** — cost to undo is very high (e.g. data store, cloud provider). Defer until you have enough data to commit.

2. **Set a trigger condition** for irreversible decisions:
   - "We will choose the database when we have 3 realistic query patterns written."
   - "We will decide on the event format when we have confirmed two consumers."

3. **Use spikes/prototypes** to gather data without committing:
   - Time-boxed (max 2 days).
   - Outcome is a decision recommendation, not production code.

### LRM Checklist
- [ ] Is this decision reversible? → Decide now.
- [ ] Is this decision irreversible? → What is the trigger condition?
- [ ] Have we set a deadline for this decision?
- [ ] Does anyone disagree? → Their objection must be captured in an ADR comment.