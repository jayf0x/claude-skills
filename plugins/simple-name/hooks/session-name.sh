#!/bin/bash
# SessionStart hook: renames session to "{repo}: {MM/DD}-{base36hash}"
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
REPO="${REPO:0:15}"
DATE=$(date +%m/%d)
HASH=$(node -e "process.stdout.write(Date.now().toString(36))" 2>/dev/null || date +%s | awk '{printf "%x", $1}')
TITLE="${REPO}: ${DATE}-${HASH}"
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Rename this session to '${TITLE}' immediately using the session rename function.\"}}"
