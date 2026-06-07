# Git Conventions (always-on)

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