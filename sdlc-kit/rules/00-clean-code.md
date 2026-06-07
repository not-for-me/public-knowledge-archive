# Clean Code Rules (always-on)

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