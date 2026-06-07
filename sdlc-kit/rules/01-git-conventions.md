---
name: sdlc-kit-core
description: Always-on coding standards — clean code rules, Git conventions, and import organization. Use in every session for consistent code quality.
---

# Clean Code Rules

## Imports

### Python (stdlib → third-party → local, absolute paths)
Organize imports in three strict blocks separated by a blank line:
1. Standard library (`os`, `sys`, `json`, `pathlib`, etc.)
2. Third-party packages (`requests`, `numpy`, `torch`, etc.)
3. Local application modules (absolute imports only — no relative imports like `from ..utils`)

Within each block, sort alphabetically.

### Kotlin (no wildcard imports)
Use explicit single-import statements only. `import java.io.File` ✓ vs `import java.io.*` ✗

### General
- No unused imports.
- No unused variables or parameters (prefix with `_` if intentionally unused).

## Functions

### Length & Complexity
- Maximum 20 lines per function (excluding docstrings and blank lines).
- Maximum 2 levels of indentation (e.g., one `if` inside one `for` is okay; deeper nesting must be refactored).

### Control Flow
- Use early return / guard clauses to flatten logic.
  - Bad: deeply nested `if` wrapping the entire function body.
  - Good: return early for edge cases, then proceed with main path.

### Documentation & Placeholders
- No bare `TODO`, `FIXME`, `HACK`, or `XXX` — every placeholder **must** include a link to a tracking issue (e.g., `#1234` or `TODO(#5678): handle edge case`).

---

# Git Conventions

## Branch Naming
Branches must follow one of these prefixes with a `/` separator:
- `fix/` — bug fixes
- `feat/` — new features
- `refactor/` — code restructuring without behavior change
- `chore/` — maintenance, tooling, CI, dependencies

Example: `fix/login-timeout`, `feat/user-api`, `refactor/session-manager`, `chore/upgrade-kotlin`

No other prefix is allowed (`hotfix/`, `feature/`, `bugfix/`, `wip/` are not permitted).

## Commit Messages (Conventional Commits)
Every commit message must follow the format: `<type>: <description>`
Allowed types: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

Examples:
```
feat: add user authentication middleware
fix: correct null pointer in session timeout
docs: update API usage in README
test: add unit tests for login validator
```

## Pull Requests
- Always squash-merge PRs into the target branch.
- Delete the source branch immediately after the merge completes.
