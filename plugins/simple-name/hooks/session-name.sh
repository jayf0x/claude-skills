#!/bin/bash
# SessionStart: compute title and write to flag file for PreToolUse to pick up
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
REPO="${REPO:0:15}"
DATE=$(date +%m/%d)
HASH=$(node -e "process.stdout.write(Date.now().toString(36))" 2>/dev/null || printf '%x' "$(date +%s)")
printf '%s' "${REPO}: ${DATE}-${HASH}" > "${HOME}/.claude/simple-name-pending"
exit 0
