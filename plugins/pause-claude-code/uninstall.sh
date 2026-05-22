#!/usr/bin/env bash
# Uninstall pause-claude-code
# Removes hook, command, and patches out the settings.json entry
set -euo pipefail

STATE_DIR="$HOME/.claude/safeclaude"
HOOK_DEST="$STATE_DIR/check-usage.sh"
SETTINGS="$HOME/.claude/settings.json"
CMD_DEST="$HOME/.claude/commands/pause-ignore.toml"

echo "Uninstalling pause-claude-code..."

if [[ -f "$HOOK_DEST" ]]; then
  rm "$HOOK_DEST"
  echo "  Removed: $HOOK_DEST"
else
  echo "  Hook not found, skipping: $HOOK_DEST"
fi

if [[ -f "$CMD_DEST" ]]; then
  rm "$CMD_DEST"
  echo "  Removed: $CMD_DEST"
else
  echo "  Command not found, skipping: $CMD_DEST"
fi

if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
  PATCHED=$(jq \
    'if .hooks.PreToolUse then
       .hooks.PreToolUse = [
         .hooks.PreToolUse[]
         | select(.hooks[]?.command? | test("check-usage.sh") | not)
       ]
     else . end' \
    "$SETTINGS" 2>/dev/null || cat "$SETTINGS")
  printf '%s\n' "$PATCHED" > "$SETTINGS"
  echo "  Removed hook entry from settings.json"
fi

echo ""
echo "Done. Config and state preserved at: $STATE_DIR"
echo "To fully clean up: rm -rf $STATE_DIR"
