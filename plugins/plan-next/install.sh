#!/usr/bin/env bash
# Install plan-next skill globally for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills/plan-next"
COMMANDS_DIR="${HOME}/.claude/commands"

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required."
  exit 1
fi

echo "Installing plan-next..."

mkdir -p "${SKILLS_DIR}/scripts"
mkdir -p "${COMMANDS_DIR}"

cp "${SCRIPT_DIR}/skills/plan-next/SKILL.md" "${SKILLS_DIR}/SKILL.md"
cp "${SCRIPT_DIR}/skills/plan-next/scripts/plan-context.sh" "${SKILLS_DIR}/scripts/plan-context.sh"
chmod +x "${SKILLS_DIR}/scripts/plan-context.sh"
cp "${SCRIPT_DIR}/commands/plan.md" "${COMMANDS_DIR}/plan.md"

echo "  Skill:   ${SKILLS_DIR}/SKILL.md"
echo "  Script:  ${SKILLS_DIR}/scripts/plan-context.sh"
echo "  Command: ${COMMANDS_DIR}/plan.md"
echo ""
echo "Done."
echo "Usage: /plan          — auto-detect next stage"
echo "       /plan b        — start Stage B explicitly"
echo "       /plan-next c   — same via full skill name"
echo ""
echo "Restart Claude Code if it was already running."
