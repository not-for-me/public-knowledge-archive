#!/bin/bash
# sdlc-kit 설치 스크립트
# SSOT (~/.hermes/sdlc-kit/ 또는 public-knowledge-archive/sdlc-kit) → 머신 레벨 설정
#
# 하는 일:
#   1. Skills → ~/.agents/skills/ (Codex) + ~/.claude/skills/ (Claude Code)
#   2. Codex Custom Agents → ~/.codex/agents/ (subagent spawn)
#   3. Claude agents → ~/.claude/agents/ (@mention subagent)
#   4. Claude rules → ~/.claude/rules/ (always-on)
#   5. ~/.codex/AGENTS.md → symlink
#   6. ~/.claude/CLAUDE.md → @import
#
# 사용법:
#   Private SSOT:    bash ~/.hermes/sdlc-kit/scripts/install.sh
#   Public archive:  bash ~/public-knowledge-archive/sdlc-kit/scripts/install.sh
#   curl-pipe:       curl -sL https://raw.githubusercontent.com/not-for-me/public-knowledge-archive/main/sdlc-kit/scripts/install.sh | bash

set -euo pipefail

# ── Script location (path-aware: works from git clone, SSOT, or curl pipe) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDLC_KIT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================"
echo "  SDLC Harness — Machine Setup"
echo "  Source: $SDLC_KIT"
echo "============================================"

# Validate
if [ ! -f "$SDLC_KIT/AGENTS.md" ]; then
  echo "  ❌  AGENTS.md not found — wrong location?"
  exit 1
fi

# ── Skill definitions (bash 3.2 compatible) ──
SKILL_DIRS="architect tdd-expert kotlin-expert python-expert spring-expert frontend-expert database-expert api-designer devops-expert security-reviewer core"

skill_name() {
  echo "sdlc-kit-$1"
}

# ── 1. Install Skills (Codex + Claude Code) ──
echo ""
echo "[1/4] Skills → Codex (~/.agents/skills/) + Claude (~/.claude/skills/)"

for dir in $SKILL_DIRS; do
  skill_name="$(skill_name "$dir")"
  src="$SDLC_KIT/skills/$dir/SKILL.md"
  [ -f "$src" ] || { echo "  ⚠  SKILL.md not found: $src — skipping"; continue; }

  # Codex
  mkdir -p "$HOME/.agents/skills/$skill_name"
  ln -sf "$src" "$HOME/.agents/skills/$skill_name/SKILL.md"

  # Claude Code
  mkdir -p "$HOME/.claude/skills/$skill_name"
  ln -sf "$src" "$HOME/.claude/skills/$skill_name/SKILL.md"

  echo "  ✅ $skill_name"
done

# ── 2. Codex Custom Agents (subagent spawn) ──
echo ""
echo "[2/4] Codex Custom Agents → ~/.codex/agents/"

mkdir -p "$HOME/.codex/agents"

cat > "$HOME/.codex/agents/architect.toml" << 'AGENTEOF'
name = "architect"
description = "Software architect — C4 modeling, ADR, technology selection, system design review"
skills.config = [{ name = "sdlc-kit-architect" }]
developer_instructions = """
You are a software architecture expert. You have the sdlc-kit-architect skill loaded.
Focus on C4 modeling, ADRs, technology selection, and cross-cutting concerns.
Provide opinions, not prescriptions. Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ architect"

cat > "$HOME/.codex/agents/tdd-expert.toml" << 'AGENTEOF'
name = "tdd-expert"
description = "TDD expert — RED-GREEN-REFACTOR cycle, testing strategy, Testcontainers"
skills.config = [{ name = "sdlc-kit-tdd-expert" }]
developer_instructions = """
You are a strict TDD practitioner. You have the sdlc-kit-tdd-expert skill loaded.
Enforce RED-GREEN-REFACTOR. Write tests first. No Thread.sleep(). Use Awaitility.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ tdd-expert"

cat > "$HOME/.codex/agents/kotlin-expert.toml" << 'AGENTEOF'
name = "kotlin-expert"
description = "Kotlin language expert — idioms, null safety, coroutines, code review"
skills.config = [{ name = "sdlc-kit-kotlin-expert" }]
developer_instructions = """
You are a Kotlin language expert. You have the sdlc-kit-kotlin-expert skill loaded.
Review Kotlin code for idiomatic usage: null safety, immutability, sealed types, coroutines.
Do NOT prescribe specific frameworks or versions.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ kotlin-expert"

cat > "$HOME/.codex/agents/python-expert.toml" << 'AGENTEOF'
name = "python-expert"
description = "Python language expert — Pythonic idioms, type hints, composition, code review"
skills.config = [{ name = "sdlc-kit-python-expert" }]
developer_instructions = """
You are a Python language expert. You have the sdlc-kit-python-expert skill loaded.
Review Python code for Pythonic idioms: Zen of Python, type hints, composition over inheritance.
Do NOT prescribe specific frameworks, package managers, or versions.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ python-expert"

cat > "$HOME/.codex/agents/spring-expert.toml" << 'AGENTEOF'
name = "spring-expert"
description = "Spring Framework & Boot expert — DI, configuration, testing, security"
skills.config = [{ name = "sdlc-kit-spring-expert" }]
developer_instructions = """
You are a Spring Framework expert. You have the sdlc-kit-spring-expert skill loaded.
Review Spring applications: constructor injection, configuration management, testing, security.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ spring-expert"

cat > "$HOME/.codex/agents/frontend-expert.toml" << 'AGENTEOF'
name = "frontend-expert"
description = "Frontend expert — component architecture, state management, performance, a11y"
skills.config = [{ name = "sdlc-kit-frontend-expert" }]
developer_instructions = """
You are a frontend architecture expert. You have the sdlc-kit-frontend-expert skill loaded.
Review frontend code: component design, state management, performance, a11y.
Do NOT prescribe specific frameworks.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ frontend-expert"

cat > "$HOME/.codex/agents/database-expert.toml" << 'AGENTEOF'
name = "database-expert"
description = "Database & data modeling expert — schema design, query optimization, migration"
skills.config = [{ name = "sdlc-kit-database-expert" }]
developer_instructions = """
You are a database expert. You have the sdlc-kit-database-expert skill loaded.
Review schemas, queries, and migrations. Advise on storage selection and normalization trade-offs.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ database-expert"

cat > "$HOME/.codex/agents/api-designer.toml" << 'AGENTEOF'
name = "api-designer"
description = "API design expert — REST, GraphQL, gRPC, versioning, contract evolution"
skills.config = [{ name = "sdlc-kit-api-designer" }]
developer_instructions = """
You are an API design expert. You have the sdlc-kit-api-designer skill loaded.
Review API contracts: resource modeling, protocol choice, versioning, error models.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ api-designer"

cat > "$HOME/.codex/agents/devops-expert.toml" << 'AGENTEOF'
name = "devops-expert"
description = "DevOps & observability expert — CI/CD, Docker, monitoring, incident response"
skills.config = [{ name = "sdlc-kit-devops-expert" }]
developer_instructions = """
You are a DevOps expert. You have the sdlc-kit-devops-expert skill loaded.
Review CI/CD pipelines, containerization, observability stacks, incident response.
Structure your response as: Observation → Assessment → Opinion → Suggestion.
"""
AGENTEOF
echo "  ✅ devops-expert"

cat > "$HOME/.codex/agents/security-reviewer.toml" << 'AGENTEOF'
name = "security-reviewer"
description = "Security reviewer — OWASP Top 10, secret scanning, vulnerability assessment"
skills.config = [{ name = "sdlc-kit-security-reviewer" }]
developer_instructions = """
You are a security expert. You have the sdlc-kit-security-reviewer skill loaded.
Conduct security reviews: OWASP Top 10, secret scanning, dependency vulnerabilities.
Structure findings as: Severity → Location → Description → Impact → Remediation.
"""
AGENTEOF
echo "  ✅ security-reviewer"

# ── 3. Claude Code Agents (@mention subagent) ──
echo ""
echo "[3/4] Claude Code Agents → ~/.claude/agents/"

mkdir -p "$HOME/.claude/agents"

for dir in $SKILL_DIRS; do
  [ "$dir" = "core" ] && continue  # core is always-on via rules, not @mention
  skill_name="$(skill_name "$dir")"
  cat > "$HOME/.claude/agents/$skill_name.md" << AGENTEOF
# $skill_name

You are an expert activated via \`@$skill_name\`.
The \`$skill_name\` skill is auto-loaded when invoked.

See \`~/.claude/skills/$skill_name/SKILL.md\` for full instructions.

Use the Observation → Assessment → Opinion → Suggestion structure.
You are not a gatekeeper — provide informed opinions; the team makes the final call.
AGENTEOF
  echo "  ✅ $skill_name"
done

# ── 4. Claude Code Rules (always-on) ──
echo ""
echo "[4/4] Claude Code Rules → ~/.claude/rules/"

mkdir -p "$HOME/.claude/rules"
CORE_SRC="$SDLC_KIT/skills/core/SKILL.md"

if [ -f "$CORE_SRC" ]; then
  ln -sf "$CORE_SRC" "$HOME/.claude/rules/00-clean-code.md"
  ln -sf "$CORE_SRC" "$HOME/.claude/rules/01-git-conventions.md"
  echo "  ✅ rules/ → sdlc-kit-core"
else
  echo "  ⚠  core skill not found — skipping rules"
fi

# ── 5. Cross-platform AGENTS.md (Codex) ──
echo ""
echo "[extra] Codex: ~/.codex/AGENTS.md"
mkdir -p "$HOME/.codex"
if [ -f "$HOME/.codex/AGENTS.md" ] && [ ! -L "$HOME/.codex/AGENTS.md" ]; then
  echo "  ⚠  ~/.codex/AGENTS.md exists as a regular file — backing up"
  mv "$HOME/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md.bak"
fi
ln -sf "$SDLC_KIT/AGENTS.md" "$HOME/.codex/AGENTS.md"
echo "  ✅ symlinked: ~/.codex/AGENTS.md → $SDLC_KIT/AGENTS.md"

# ── 6. Claude CLAUDE.md (@import) ──
echo ""
echo "[extra] Claude: ~/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"
CLAUDE_REL="../.codex/AGENTS.md"
cat > "$HOME/.claude/CLAUDE.md" << CLAUDE
# Claude Code Global Instructions

This file delegates to the shared cross-agent configuration.
Skills are auto-discovered from \`~/.claude/skills/\`. Do NOT edit this file directly.

\`\`\`
SSOT (private):   ~/.hermes/sdlc-kit/
Public archive:   $(git -C "$SDLC_KIT" remote get-url origin 2>/dev/null || echo "$SDLC_KIT")
\`\`\`

@import $CLAUDE_REL
CLAUDE
echo "  ✅ wrote: ~/.claude/CLAUDE.md (@import $CLAUDE_REL)"

# ── Done ──
echo ""
echo "============================================"
echo "  ✅  SDLC Harness installed!"
echo ""
echo "  Codex Skills:   ~/.agents/skills/sdlc-kit-*/"
echo "  Codex Agents:   ~/.codex/agents/*.toml"
echo "  Claude Skills:  ~/.claude/skills/sdlc-kit-*/"
echo "  Claude Agents:  ~/.claude/agents/*.md"
echo "  Claude Rules:   ~/.claude/rules/"
echo ""
echo "  Update:  git -C $SDLC_KIT pull && bash $0"
echo "============================================"