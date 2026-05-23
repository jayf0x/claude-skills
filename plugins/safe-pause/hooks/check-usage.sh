#!/usr/bin/env bash
# PreToolUse hook: blocks or warns when Claude.ai subscription usage crosses thresholds.
# Reads usage from the local bridge server (usage-server.py) or falls back to
# the last-written usage.json. Fails open on any error.
set -euo pipefail

STATE_DIR="$HOME/.claude/safeclaude"
CONFIG_FILE="$STATE_DIR/config.json"
USAGE_FILE="$STATE_DIR/usage.json"
IGNORE_FILE="$STATE_DIR/ignore-until"

bail() { exit 0; }

STDIN=$(cat)

# check ignore window
if [[ -f "$IGNORE_FILE" ]]; then
  IGNORE_UNTIL=$(cat "$IGNORE_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [[ "$NOW" -lt "$IGNORE_UNTIL" ]] 2>/dev/null; then
    exit 0
  fi
fi

command -v jq &>/dev/null || bail

# load config
WARN_PERCENT=75
PAUSE_PERCENT=90
SERVER_PORT=2999

if [[ -f "$CONFIG_FILE" ]]; then
  W=$(jq -r '.warn_at_percent // empty' "$CONFIG_FILE" 2>/dev/null)
  P=$(jq -r '.pause_at_percent // empty' "$CONFIG_FILE" 2>/dev/null)
  S=$(jq -r '.server_port // empty' "$CONFIG_FILE" 2>/dev/null)
  [[ -n "$W" ]] && WARN_PERCENT="$W"
  [[ -n "$P" ]] && PAUSE_PERCENT="$P"
  [[ -n "$S" ]] && SERVER_PORT="$S"
fi

# fetch usage: try bridge server first, fall back to cached file
USAGE_JSON=""
if command -v curl &>/dev/null; then
  USAGE_JSON=$(curl -sf --max-time 2 "http://127.0.0.1:${SERVER_PORT}/usage" 2>/dev/null || true)
fi
if [[ -z "$USAGE_JSON" && -f "$USAGE_FILE" ]]; then
  USAGE_JSON=$(cat "$USAGE_FILE" 2>/dev/null || true)
fi
[[ -z "$USAGE_JSON" ]] && bail

# compute effective percent as max(five_hour, seven_day) * 100
PERCENT=$(printf '%s' "$USAGE_JSON" | jq -r '
  [(.five_hour.utilization // 0), (.seven_day.utilization // 0)] | max | (. * 100 | floor)
' 2>/dev/null) || bail
[[ "$PERCENT" =~ ^[0-9]+$ ]] || bail

# identify which bucket is dominant for messaging
BUCKET=$(printf '%s' "$USAGE_JSON" | jq -r '
  if (.five_hour.utilization // 0) > (.seven_day.utilization // 0)
  then "five_hour"
  else "seven_day"
  end
' 2>/dev/null) || BUCKET="seven_day"

if [[ "$PERCENT" -lt "$WARN_PERCENT" ]]; then
  exit 0
fi

if [[ "$PERCENT" -ge "$PAUSE_PERCENT" ]]; then
  printf '{"decision":"block","reason":"Claude subscription usage at %d%% (%s). Tool call paused to protect remaining quota. Run /pause-ignore to continue anyway."}\n' \
    "$PERCENT" "$BUCKET"
  exit 2
fi

printf '{"additionalContext":"[safe-pause] Subscription usage at %d%% (%s, warn threshold %d%%). Approaching pause threshold of %d%%."}\n' \
  "$PERCENT" "$BUCKET" "$WARN_PERCENT" "$PAUSE_PERCENT"
exit 0
