#!/usr/bin/env bash
# Install safe-pause (v2 — real subscription usage monitoring)
# Sets up: hook, config, bridge server, launchd daemon, extension files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.claude/safeclaude"
SETTINGS="$HOME/.claude/settings.json"
COMMANDS_DIR="$HOME/.claude/commands"
PLIST_LABEL="com.claudeskills.usagebridge"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

for dep in jq curl python3; do
  if ! command -v "$dep" &>/dev/null; then
    echo "ERROR: $dep is required. Install with: brew install $dep"
    exit 1
  fi
done

echo "Installing safe-pause..."

mkdir -p "$STATE_DIR"

# hook
cp "$SCRIPT_DIR/hooks/check-usage.sh" "$STATE_DIR/check-usage.sh"
chmod +x "$STATE_DIR/check-usage.sh"
echo "  Hook:      $STATE_DIR/check-usage.sh"

# config
if [[ -f "$STATE_DIR/config.json" ]]; then
  echo "  Config:    already exists, skipping ($STATE_DIR/config.json)"
else
  cp "$SCRIPT_DIR/config.default.json" "$STATE_DIR/config.json"
  echo "  Config:    $STATE_DIR/config.json"
fi

# bridge server
cp "$SCRIPT_DIR/server/usage-server.py" "$STATE_DIR/usage-server.py"
chmod +x "$STATE_DIR/usage-server.py"
echo "  Server:    $STATE_DIR/usage-server.py"

# extension files
mkdir -p "$STATE_DIR/extension"
cp "$SCRIPT_DIR/extension/"* "$STATE_DIR/extension/"
echo "  Extension: $STATE_DIR/extension/"

# command
mkdir -p "$COMMANDS_DIR"
cp "$SCRIPT_DIR/commands/pause-ignore.toml" "$COMMANDS_DIR/pause-ignore.toml"
echo "  Command:   $COMMANDS_DIR/pause-ignore.toml"

# register PreToolUse hook in settings.json
if [[ ! -f "$SETTINGS" ]]; then
  printf '{"hooks":{"PreToolUse":[]}}\n' > "$SETTINGS"
fi

if jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command? | test("check-usage.sh"))' "$SETTINGS" &>/dev/null; then
  echo "  Hook already registered in settings.json, skipping"
else
  HOOK_ENTRY=$(printf '{"matcher":".*","hooks":[{"type":"command","command":"%s"}]}' "$STATE_DIR/check-usage.sh")
  PATCHED=$(jq \
    --argjson entry "$HOOK_ENTRY" \
    '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [$entry])' \
    "$SETTINGS")
  printf '%s\n' "$PATCHED" > "$SETTINGS"
  echo "  Registered PreToolUse hook in settings.json"
fi

# launchd plist for bridge server (macOS)
if [[ "$(uname)" == "Darwin" ]]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${PLIST_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(command -v python3)</string>
    <string>${STATE_DIR}/usage-server.py</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${STATE_DIR}/usage-server.log</string>
  <key>StandardErrorPath</key>
  <string>${STATE_DIR}/usage-server.log</string>
</dict>
</plist>
PLIST
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
  launchctl load "$PLIST_PATH"
  echo "  Daemon:    $PLIST_PATH (loaded)"
fi

echo ""
echo "Done. Restart Claude Code for the hook to take effect."
echo ""
echo "NEXT STEP — load the extension:"
echo "  1. In Claude Code: Extensions → Install unpacked extensions..."
echo "  2. Select: $STATE_DIR/extension/"
echo "  3. Open https://claude.ai to trigger org ID extraction"
echo ""
echo "Config: $STATE_DIR/config.json"
echo "To bypass temporarily: /pause-ignore [duration]"
