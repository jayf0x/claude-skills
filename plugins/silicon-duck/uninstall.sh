#!/usr/bin/env bash
# Uninstall silicon-duck skill
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills/silicon-duck"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "Uninstalling silicon-duck..."

rm -rf "${SKILLS_DIR}"
rm -f "${COMMANDS_DIR}/duck.md"

echo "Done."
