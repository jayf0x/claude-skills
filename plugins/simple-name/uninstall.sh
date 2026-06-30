#!/usr/bin/env bash
# Uninstall simple-name
set -euo pipefail

SESSION_HOOK="${HOME}/.claude/simple-name-session.sh"
PRETOOL_HOOK="${HOME}/.claude/simple-name-pretool.sh"
PENDING="${HOME}/.claude/simple-name-pending"
SETTINGS="${HOME}/.claude/settings.json"

echo "Uninstalling simple-name..."

for f in "${SESSION_HOOK}" "${PRETOOL_HOOK}" "${PENDING}"; do
  [[ -f "$f" ]] && rm "$f" && echo "  Removed: $f"
done

if [[ -f "${SETTINGS}" ]]; then
  PATCHED=$(jq '
    del(.hooks.SessionStart[]? | select(.hooks[]?.command? | test("simple-name-session"))) |
    del(.hooks.PreToolUse[]? | select(.hooks[]?.command? | test("simple-name-pretool")))
  ' "${SETTINGS}" 2>/dev/null || cat "${SETTINGS}")
  printf '%s\n' "${PATCHED}" > "${SETTINGS}"
  echo "  Removed hooks from settings.json"
fi

echo ""
echo "Done. Restart Claude Code for changes to take effect."
