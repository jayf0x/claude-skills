#!/usr/bin/env bash
# Install simple-name: auto-renames sessions to {repo}: {MM/DD}-{hash}
# via the documented SessionStart hook `sessionTitle` field, plus a
# background watcher that reasserts the title for ~90s against
# Anthropic's auto-titler bug (anthropics/claude-code#23610).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_HOOK="${HOME}/.claude/simple-name-session.sh"
SETTINGS="${HOME}/.claude/settings.json"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install: brew install jq"
  exit 1
fi

echo "Installing simple-name..."

cp "${SCRIPT_DIR}/hooks/session-name.sh" "${SESSION_HOOK}"
chmod +x "${SESSION_HOOK}"
echo "  Hook: ${SESSION_HOOK}"

[[ -f "${SETTINGS}" ]] || printf '{"hooks":{}}\n' > "${SETTINGS}"

if jq -e '.hooks.SessionStart[]?.hooks[]?.command? | test("simple-name-session")' "${SETTINGS}" &>/dev/null; then
  echo "  SessionStart hook already registered, skipping"
else
  ENTRY=$(printf '{"hooks":[{"type":"command","command":"%s"}]}' "${SESSION_HOOK}")
  PATCHED=$(jq --argjson e "${ENTRY}" '.hooks.SessionStart = ((.hooks.SessionStart // []) + [$e])' "${SETTINGS}")
  printf '%s\n' "${PATCHED}" > "${SETTINGS}"
  echo "  Registered SessionStart hook"
fi

echo ""
echo "Done. Restart Claude Code / Claude Desktop for changes to take effect."
echo "Debug log: ~/.claude/simple-name-debug.log"
