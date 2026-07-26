#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills/my-style"
COMMAND_FILE="${HOME}/.claude/commands/my-style.md"

echo "Uninstalling my-style..."
echo "Note: leaving ${SKILLS_DIR}/memory.md and cache.md in place (your rules)."
echo "Delete manually if you want them gone: rm -rf ${SKILLS_DIR}"

rm -f "${SKILLS_DIR}/SKILL.md"
rm -f "${COMMAND_FILE}"

echo "Done."
