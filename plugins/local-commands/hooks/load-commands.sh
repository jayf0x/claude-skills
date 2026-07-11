#!/usr/bin/env bash
# SessionStart hook: inject the local-commands cheat sheet into session context.
FILE="$HOME/.claude/cache/local-commands/all-local-commands.md"
if [[ -s "$FILE" ]]; then
  echo "LOCAL COMMANDS CHEAT SHEET (known-good machine-specific commands — prefer these over generic defaults):"
  cat "$FILE"
fi
exit 0
