#!/usr/bin/env bash
# Install pause-claude-code
# Copies hook + config, registers PreToolUse hook in ~/.claude/settings.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.claude/safeclaude"
HOOK_SRC="$SCRIPT_DIR/hooks/check-usage.sh"
HOOK_DEST="$STATE_DIR/check-usage.sh"
CONFIG_SRC="$SCRIPT_DIR/config.default.json"
CONFIG_DEST="$STATE_DIR/config.json"
SETTINGS="$HOME/.claude/settings.json"
COMMANDS_DIR="$HOME/.claude/commands"
CMD_SRC="$SCRIPT_DIR/commands/pause-ignore.toml"
CMD_DEST="$COMMANDS_DIR/pause-ignore.toml"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq"
  exit 1
fi

echo "Installing pause-claude-code..."

mkdir -p "$STATE_DIR"

cp "$HOOK_SRC" "$HOOK_DEST"
chmod +x "$HOOK_DEST"
echo "  Hook:    $HOOK_DEST"

if [[ -f "$CONFIG_DEST" ]]; then
  echo "  Config:  already exists, skipping ($CONFIG_DEST)"
else
  cp "$CONFIG_SRC" "$CONFIG_DEST"
  echo "  Config:  $CONFIG_DEST"
fi

mkdir -p "$COMMANDS_DIR"
cp "$CMD_SRC" "$CMD_DEST"
echo "  Command: $CMD_DEST"

if [[ ! -f "$SETTINGS" ]]; then
  printf '{"hooks":{"PreToolUse":[]}}\n' > "$SETTINGS"
fi

if jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command? | test("check-usage.sh"))' "$SETTINGS" &>/dev/null; then
  echo "  Hook already registered in settings.json, skipping"
else
  HOOK_ENTRY=$(printf '{"matcher":".*","hooks":[{"type":"command","command":"%s"}]}' "$HOOK_DEST")
  PATCHED=$(jq \
    --argjson entry "$HOOK_ENTRY" \
    '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [$entry])' \
    "$SETTINGS")
  printf '%s\n' "$PATCHED" > "$SETTINGS"
  echo "  Registered PreToolUse hook in settings.json"
fi

echo ""
echo "Done. Restart Claude Code for the hook to take effect."
echo "Config: $CONFIG_DEST"
echo "To adjust thresholds: edit $CONFIG_DEST"
echo "To bypass temporarily: /pause-ignore [duration]"
