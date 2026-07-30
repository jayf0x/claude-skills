#!/usr/bin/env bash
# Uninstall git-meow skill
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills/git-meow"
CMD_DEST="${HOME}/.claude/commands/git-meow.md"
STATE_FILE="${SKILLS_DIR}/.prev-global-hookspath"

echo "Uninstalling git-meow..."

current_hooks_path="$(git config --global core.hooksPath 2>/dev/null || true)"
if [[ "$current_hooks_path" == "${SKILLS_DIR}/githooks" ]]; then
  git config --global --unset core.hooksPath
  if [[ -f "$STATE_FILE" ]]; then
    prev="$(cat "$STATE_FILE")"
    git config --global core.hooksPath "$prev"
    echo "  Restored previous global core.hooksPath: $prev"
  else
    echo "  Removed global core.hooksPath override (plain 'git commit' works again everywhere)"
  fi
else
  echo "  Global core.hooksPath isn't pointed at git-meow, leaving it alone: ${current_hooks_path:-<unset>}"
fi

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
