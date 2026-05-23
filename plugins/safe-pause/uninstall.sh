#!/usr/bin/env bash
# Uninstall safe-pause
set -euo pipefail

STATE_DIR="$HOME/.claude/safeclaude"
SETTINGS="$HOME/.claude/settings.json"
CMD_DEST="$HOME/.claude/commands/pause-ignore.toml"
PLIST_LABEL="com.claudeskills.usagebridge"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

echo "Uninstalling safe-pause..."

# stop + remove launchd daemon
if [[ "$(uname)" == "Darwin" && -f "$PLIST_PATH" ]]; then
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
  rm "$PLIST_PATH"
  echo "  Removed daemon: $PLIST_PATH"
fi

# remove hook file
if [[ -f "$STATE_DIR/check-usage.sh" ]]; then
  rm "$STATE_DIR/check-usage.sh"
  echo "  Removed: $STATE_DIR/check-usage.sh"
fi

# remove command
if [[ -f "$CMD_DEST" ]]; then
  rm "$CMD_DEST"
  echo "  Removed: $CMD_DEST"
fi

# patch out settings.json entry
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
echo "Done. State preserved at: $STATE_DIR"
echo "To fully clean up: rm -rf $STATE_DIR"
echo ""
echo "Also remove the extension manually:"
echo "  Extensions → Manage extensions → Claude Usage Monitor → Remove"
