#!/usr/bin/env bash
# Uninstall simple-name
set -euo pipefail

HOOK_DEST="${HOME}/.claude/simple-name-session.sh"
SETTINGS="${HOME}/.claude/settings.json"

echo "Uninstalling simple-name..."

if [[ -f "${HOOK_DEST}" ]]; then
  rm "${HOOK_DEST}"
  echo "  Removed: ${HOOK_DEST}"
fi

if [[ -f "${SETTINGS}" ]]; then
  PATCHED=$(jq 'del(.hooks.SessionStart[]? | select(.hooks[]?.command? | test("simple-name-session")))' "${SETTINGS}" 2>/dev/null || cat "${SETTINGS}")
  printf '%s\n' "${PATCHED}" > "${SETTINGS}"
  echo "  Removed hook from settings.json"
fi

echo ""
echo "Done. Restart Claude Code for changes to take effect."
