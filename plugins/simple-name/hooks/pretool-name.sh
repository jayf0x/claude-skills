#!/bin/bash
# PreToolUse: on first tool call, wait until 2s after session start, then inject rename
PENDING="${HOME}/.claude/simple-name-pending"
LOG="${HOME}/.claude/simple-name-debug.log"

if [[ ! -f "${PENDING}" ]]; then
  printf '[%s] PreToolUse fired — no flag, skipping\n' "$(date '+%H:%M:%S')" >> "${LOG}"
  exit 0
fi

CREATED=$(cut -d'|' -f1 "${PENDING}")
TITLE=$(cut -d'|' -f2- "${PENDING}")
rm "${PENDING}"

NOW=$(date +%s)
ELAPSED=$((NOW - CREATED))
DELAY=2

if [[ ${ELAPSED} -lt ${DELAY} ]]; then
  WAIT=$((DELAY - ELAPSED))
  printf '[%s] PreToolUse fired — sleeping %ds to let auto-name settle | title: %s\n' "$(date '+%H:%M:%S')" "${WAIT}" "${TITLE}" >> "${LOG}"
  sleep "${WAIT}"
else
  printf '[%s] PreToolUse fired — no sleep needed (%ds elapsed) | title: %s\n' "$(date '+%H:%M:%S')" "${ELAPSED}" "${TITLE}" >> "${LOG}"
fi

printf '[%s] Injecting rename instruction\n' "$(date '+%H:%M:%S')" >> "${LOG}"
printf '{"additionalContext":"BEFORE executing this tool: rename this session to '\''%s'\'' using the session rename function. Do that first, then proceed normally."}\n' "${TITLE}"
