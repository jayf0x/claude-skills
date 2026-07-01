#!/bin/bash
# SessionStart hook: sets the session title to "{repo}: {MM/DD}-{hash}"
# via the documented `sessionTitle` output field (same effect as /rename).
# Anthropic's auto-titler can overwrite this shortly after (known bug,
# see anthropics/claude-code#23610), so a detached background watcher
# reasserts the title for ~90s by patching the Desktop app's session
# storage JSON directly if it detects an overwrite.
LOG="${HOME}/.claude/simple-name-debug.log"
SESSIONS_BASE="${HOME}/Library/Application Support/Claude/claude-code-sessions"

STDIN_JSON=$(cat)
SOURCE=$(printf '%s' "${STDIN_JSON}" | jq -r '.source // empty')
CWD=$(printf '%s' "${STDIN_JSON}" | jq -r '.cwd // empty')
SESSION_ID=$(printf '%s' "${STDIN_JSON}" | jq -r '.session_id // empty')
EXISTING_TITLE=$(printf '%s' "${STDIN_JSON}" | jq -r '.session_title // empty')

printf '[%s] SessionStart fired — source=%s cwd=%s existing_title=%s\n' \
  "$(date '+%H:%M:%S')" "${SOURCE}" "${CWD}" "${EXISTING_TITLE}" >> "${LOG}"

# don't clobber a title the user already set on a resumed session
if [[ "${SOURCE}" == "resume" && -n "${EXISTING_TITLE}" ]]; then
  printf '[%s] Resume with existing title, skipping\n' "$(date '+%H:%M:%S')" >> "${LOG}"
  exit 0
fi

if [[ "${SOURCE}" != "startup" && "${SOURCE}" != "resume" ]]; then
  printf '[%s] source=%s not startup/resume, skipping\n' "$(date '+%H:%M:%S')" "${SOURCE}" >> "${LOG}"
  exit 0
fi

REPO=$(basename "${CWD:-$(pwd)}")
REPO="${REPO:0:15}"
DATE=$(date +%m/%d)
HASH=$(node -e "process.stdout.write(Date.now().toString(36))" 2>/dev/null || printf '%x' "$(date +%s)")
TITLE="${REPO}: ${DATE}-${HASH}"

printf '[%s] Setting sessionTitle=%s\n' "$(date '+%H:%M:%S')" "${TITLE}" >> "${LOG}"

# detached watcher: reassert the title if the auto-titler overwrites it
nohup bash -c '
  LOG="$1"; SESSIONS_BASE="$2"; SESSION_ID="$3"; TITLE="$4"
  [[ -z "$SESSION_ID" ]] && exit 0

  find_file() {
    grep -rl "\"cliSessionId\": *\"${SESSION_ID}\"" "${SESSIONS_BASE}" --include="*.json" 2>/dev/null | head -1
  }

  sleep 3
  FILE=""
  for i in $(seq 1 10); do
    FILE=$(find_file)
    [[ -n "$FILE" ]] && break
    sleep 1
  done
  if [[ -z "$FILE" ]]; then
    printf "[%s] watcher: no session file found for %s, giving up\n" "$(date "+%H:%M:%S")" "$SESSION_ID" >> "$LOG"
    exit 0
  fi
  printf "[%s] watcher: tracking %s\n" "$(date "+%H:%M:%S")" "$FILE" >> "$LOG"

  for i in $(seq 1 45); do
    sleep 2
    CUR=$(jq -r ".title" "$FILE" 2>/dev/null)
    if [[ "$CUR" != "$TITLE" ]]; then
      printf "[%s] watcher: auto-titler overwrote title (now: %s) — reasserting\n" "$(date "+%H:%M:%S")" "$CUR" >> "$LOG"
      TMP="${FILE}.simple-name.tmp"
      jq --arg t "$TITLE" "(.title) = \$t | (.titleSource) = \"manual\"" "$FILE" > "$TMP" 2>>"$LOG" && mv -f "$TMP" "$FILE"
    fi
  done
  printf "[%s] watcher: done\n" "$(date "+%H:%M:%S")" >> "$LOG"
' _ "${LOG}" "${SESSIONS_BASE}" "${SESSION_ID}" "${TITLE}" >> "${LOG}" 2>&1 &
disown

jq -n --arg t "${TITLE}" '{"hookSpecificOutput":{"hookEventName":"SessionStart","sessionTitle":$t}}'
