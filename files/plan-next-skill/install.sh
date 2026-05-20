#!/usr/bin/env bash
# install.sh — Install the plan-next skill globally for Claude Code
# Run from the directory containing this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILLS_DIR="${HOME}/.claude/skills/plan-next"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "Installing plan-next skill..."

# Create dirs
mkdir -p "${SKILLS_DIR}/scripts"
mkdir -p "${COMMANDS_DIR}"

# Copy skill files
cp "${SCRIPT_DIR}/plan-next/SKILL.md" "${SKILLS_DIR}/SKILL.md"
cp "${SCRIPT_DIR}/plan-next/scripts/plan-context.sh" "${SKILLS_DIR}/scripts/plan-context.sh"
chmod +x "${SKILLS_DIR}/scripts/plan-context.sh"

# Copy /plan command shim
cp "${SCRIPT_DIR}/commands/plan.md" "${COMMANDS_DIR}/plan.md"

echo ""
echo "✓ Installed to:"
echo "  ${SKILLS_DIR}/SKILL.md"
echo "  ${SKILLS_DIR}/scripts/plan-context.sh"
echo "  ${COMMANDS_DIR}/plan.md"
echo ""
echo "Usage in Claude Code:"
echo "  /plan          → auto-detect and start the next stage"
echo "  /plan next     → same as above"
echo "  /plan b        → start Stage B explicitly"
echo "  /plan-next c   → start Stage C via full skill name"
echo ""
echo "Restart Claude Code if it was already running."
