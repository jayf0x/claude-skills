#!/usr/bin/env bash
# Install silicon-duck skill for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills/silicon-duck"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "Installing silicon-duck..."

mkdir -p "${SKILLS_DIR}"
mkdir -p "${COMMANDS_DIR}"

cp "${SCRIPT_DIR}/skills/silicon-duck/SKILL.md" "${SKILLS_DIR}/SKILL.md"
cp "${SCRIPT_DIR}/commands/duck.md" "${COMMANDS_DIR}/duck.md"

echo "  Skill:   ${SKILLS_DIR}/SKILL.md"
echo "  Command: ${COMMANDS_DIR}/duck.md"
echo ""
echo "Done."
echo "Usage: /duck          — show status"
echo "       /duck disable  — hide CIP block this session"
echo "       /duck enable   — re-enable CIP block"
echo ""
echo "Restart Claude Code if it was already running."
