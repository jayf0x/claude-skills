#!/bin/bash
# SessionStart: compute title, write flag with timestamp for PreToolUse
LOG="${HOME}/.claude/simple-name-debug.log"
PENDING="${HOME}/.claude/simple-name-pending"

REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
REPO="${REPO:0:15}"
DATE=$(date +%m/%d)
HASH=$(node -e "process.stdout.write(Date.now().toString(36))" 2>/dev/null || printf '%x' "$(date +%s)")
TITLE="${REPO}: ${DATE}-${HASH}"

printf '%s|%s\n' "$(date +%s)" "${TITLE}" > "${PENDING}"
printf '[%s] SessionStart fired — title: %s | flag written: %s\n' "$(date '+%H:%M:%S')" "${TITLE}" "${PENDING}" >> "${LOG}"
exit 0
