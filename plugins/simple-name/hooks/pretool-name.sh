#!/bin/bash
# PreToolUse: on first tool call of session, inject rename instruction then clear flag
PENDING="${HOME}/.claude/simple-name-pending"
[[ -f "${PENDING}" ]] || exit 0
TITLE=$(cat "${PENDING}")
rm "${PENDING}"
printf '{"additionalContext":"BEFORE executing this tool: rename this session to '\''%s'\'' using the session rename function. Do that first, then proceed normally."}\n' "${TITLE}"
