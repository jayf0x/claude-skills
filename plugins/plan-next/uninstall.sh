#!/usr/bin/env bash
# Uninstall plan-next skill
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills/plan-next"
CMD_DEST="${HOME}/.claude/commands/plan.md"

echo "Uninstalling plan-next..."

if [[ -d "$SKILLS_DIR" ]]; then
  rm -rf "$SKILLS_DIR"
  echo "  Removed: $SKILLS_DIR"
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
