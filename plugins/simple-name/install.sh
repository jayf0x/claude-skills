#!/usr/bin/env bash
# Install simple-name: SessionStart hook that auto-renames sessions to {repo}: {MM/DD}-{hash}
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DEST="${HOME}/.claude/simple-name-session.sh"
SETTINGS="${HOME}/.claude/settings.json"

echo "Installing simple-name..."

cp "${SCRIPT_DIR}/hooks/session-name.sh" "${HOOK_DEST}"
chmod +x "${HOOK_DEST}"
echo "  Hook: ${HOOK_DEST}"

if [[ ! -f "${SETTINGS}" ]]; then
  printf '{"hooks":{}}\n' > "${SETTINGS}"
fi

if jq -e '.hooks.SessionStart[]?.hooks[]?.command? | test("simple-name-session")' "${SETTINGS}" &>/dev/null; then
  echo "  Hook already registered in settings.json, skipping"
else
  HOOK_ENTRY=$(printf '{"hooks":[{"type":"command","command":"%s"}]}' "${HOOK_DEST}")
  PATCHED=$(jq --argjson entry "${HOOK_ENTRY}" \
    '.hooks.SessionStart = ((.hooks.SessionStart // []) + [$entry])' \
    "${SETTINGS}")
  printf '%s\n' "${PATCHED}" > "${SETTINGS}"
  echo "  Registered SessionStart hook in settings.json"
fi

echo ""
echo "Done. Restart Claude Code for changes to take effect."
