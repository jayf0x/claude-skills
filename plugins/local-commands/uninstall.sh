#!/usr/bin/env bash
# Uninstall local-commands: removes commands, hook, settings.json entry, and cached files
set -euo pipefail

SETTINGS="${HOME}/.claude/settings.json"

echo "Uninstalling local-commands..."

rm -f "${HOME}/.claude/commands/cmds-collect.md" "${HOME}/.claude/commands/cmds-compress.md"
rm -rf "${HOME}/.claude/cache/local-commands"

if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
  PATCHED=$(jq '
    if .hooks.SessionStart then
      .hooks.SessionStart = [
        .hooks.SessionStart[]
        | select(.hooks[]?.command? | test("load-commands.sh") | not)
      ]
    else . end
  ' "$SETTINGS")
  printf '%s\n' "$PATCHED" > "$SETTINGS"
  echo "  Removed SessionStart hook from settings.json"
fi

echo "Done. No residue left."
