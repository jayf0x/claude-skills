#!/usr/bin/env bash
# Uninstall commit-mauw skill
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills/commit-mauw"
CMD_DEST="${HOME}/.claude/commands/commit-mauw.md"

echo "Uninstalling commit-mauw..."

if [[ -d "$SKILLS_DIR" ]]; then
  rm -rf "$SKILLS_DIR"
  echo "  Removed: $SKILLS_DIR (including your persona customization — copy SKILL.md out first if you want to keep it)"
else
  echo "  Skill dir not found, skipping: $SKILLS_DIR"
fi

if [[ -f "$CMD_DEST" ]]; then
  rm "$CMD_DEST"
  echo "  Removed: $CMD_DEST"
else
  echo "  Command not found, skipping: $CMD_DEST"
fi

echo ""
echo "Done."
