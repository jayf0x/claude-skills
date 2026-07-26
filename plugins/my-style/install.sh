#!/usr/bin/env bash
# Install my-style skill globally for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills/my-style"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "Installing my-style..."

mkdir -p "${SKILLS_DIR}"
mkdir -p "${COMMANDS_DIR}"

cp "${SCRIPT_DIR}/skills/my-style/SKILL.md" "${SKILLS_DIR}/SKILL.md"

# memory.md and cache.md are user data — don't clobber on reinstall.
if [ ! -f "${SKILLS_DIR}/memory.md" ]; then
  cp "${SCRIPT_DIR}/skills/my-style/memory.md" "${SKILLS_DIR}/memory.md"
fi
if [ ! -f "${SKILLS_DIR}/cache.md" ]; then
  cp "${SCRIPT_DIR}/skills/my-style/cache.md" "${SKILLS_DIR}/cache.md"
fi

cp "${SCRIPT_DIR}/commands/my-style.md" "${COMMANDS_DIR}/my-style.md"

echo "  Skill:   ${SKILLS_DIR}/SKILL.md"
echo "  Memory:  ${SKILLS_DIR}/memory.md"
echo "  Cache:   ${SKILLS_DIR}/cache.md"
echo "  Command: ${COMMANDS_DIR}/my-style.md"
echo ""
echo "Done."
echo "Usage: /my-style              — load the skill"
echo "       /my-style add <text>   — append a rule to cache.md"
echo "       /my-style merge        — reconcile cache.md into memory.md"
echo ""
echo "Restart Claude Code if it was already running."
