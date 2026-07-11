#!/usr/bin/env bash
# Install local-commands globally for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_DIR="${HOME}/.claude/commands"
CACHE_DIR="${HOME}/.claude/cache/local-commands"
SETTINGS="${HOME}/.claude/settings.json"
HOOK="${CACHE_DIR}/load-commands.sh"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install: brew install jq"
  exit 1
fi

echo "Installing local-commands..."

mkdir -p "${COMMANDS_DIR}" "${CACHE_DIR}"
cp "${SCRIPT_DIR}/commands/cmds-collect.md" "${COMMANDS_DIR}/cmds-collect.md"
cp "${SCRIPT_DIR}/commands/cmds-compress.md" "${COMMANDS_DIR}/cmds-compress.md"
cp "${SCRIPT_DIR}/hooks/load-commands.sh" "${HOOK}"
chmod +x "${HOOK}"

# Register SessionStart hook in settings.json
if [[ ! -f "$SETTINGS" ]]; then
  printf '{}\n' > "$SETTINGS"
fi
if jq -e '.hooks.SessionStart[]? | select(.hooks[]?.command? | test("load-commands.sh"))' "$SETTINGS" &>/dev/null; then
  echo "  Hook already registered in settings.json, skipping"
else
  ENTRY=$(printf '{"matcher":"startup","hooks":[{"type":"command","command":"%s"}]}' "$HOOK")
  PATCHED=$(jq --argjson entry "$ENTRY" \
    '.hooks.SessionStart = ((.hooks.SessionStart // []) + [$entry])' "$SETTINGS")
  printf '%s\n' "$PATCHED" > "$SETTINGS"
  echo "  Registered SessionStart hook in settings.json"
fi

echo "  Commands: ${COMMANDS_DIR}/cmds-collect.md, cmds-compress.md"
echo "  Hook:     ${HOOK}"
echo "  Cache:    ${CACHE_DIR}/"
echo ""
echo "Done."
echo "Usage: /cmds-collect   — dump this session's useful commands to the cache"
echo "       /cmds-compress  — merge dumps into all-local-commands.md (auto-loaded each session)"
echo ""
echo "Restart Claude Code if it was already running."
