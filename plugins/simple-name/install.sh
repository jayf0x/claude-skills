#!/usr/bin/env bash
# Install simple-name: auto-renames sessions to {repo}: {MM/DD}-{hash}
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_HOOK="${HOME}/.claude/simple-name-session.sh"
PRETOOL_HOOK="${HOME}/.claude/simple-name-pretool.sh"
SETTINGS="${HOME}/.claude/settings.json"

echo "Installing simple-name..."

cp "${SCRIPT_DIR}/hooks/session-name.sh" "${SESSION_HOOK}"
cp "${SCRIPT_DIR}/hooks/pretool-name.sh" "${PRETOOL_HOOK}"
chmod +x "${SESSION_HOOK}" "${PRETOOL_HOOK}"
echo "  Hooks: ${SESSION_HOOK}"
echo "         ${PRETOOL_HOOK}"

[[ -f "${SETTINGS}" ]] || printf '{"hooks":{}}\n' > "${SETTINGS}"

# Register SessionStart hook
if jq -e '.hooks.SessionStart[]?.hooks[]?.command? | test("simple-name-session")' "${SETTINGS}" &>/dev/null; then
  echo "  SessionStart hook already registered, skipping"
else
  ENTRY=$(printf '{"hooks":[{"type":"command","command":"%s"}]}' "${SESSION_HOOK}")
  PATCHED=$(jq --argjson e "${ENTRY}" '.hooks.SessionStart = ((.hooks.SessionStart // []) + [$e])' "${SETTINGS}")
  printf '%s\n' "${PATCHED}" > "${SETTINGS}"
  echo "  Registered SessionStart hook"
fi

# Register PreToolUse hook
if jq -e '.hooks.PreToolUse[]?.hooks[]?.command? | test("simple-name-pretool")' "${SETTINGS}" &>/dev/null; then
  echo "  PreToolUse hook already registered, skipping"
else
  ENTRY=$(printf '{"matcher":".*","hooks":[{"type":"command","command":"%s"}]}' "${PRETOOL_HOOK}")
  PATCHED=$(jq --argjson e "${ENTRY}" '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [$e])' "${SETTINGS}")
  printf '%s\n' "${PATCHED}" > "${SETTINGS}"
  echo "  Registered PreToolUse hook"
fi

echo ""
echo "Done. Restart Claude Code for changes to take effect."
