#!/usr/bin/env bash
# PreToolUse hook: blocks or warns when context window usage crosses thresholds.
# Fails open on any error (exit 0) so it never breaks normal Claude operation.
set -euo pipefail

STATE_DIR="$HOME/.claude/safeclaude"
CONFIG_FILE="$STATE_DIR/config.json"
IGNORE_FILE="$STATE_DIR/ignore-until"

# --- fail-open helper ---
bail() { exit 0; }

# --- read stdin ---
STDIN=$(cat)

# --- check ignore window ---
if [[ -f "$IGNORE_FILE" ]]; then
  IGNORE_UNTIL=$(cat "$IGNORE_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [[ "$NOW" -lt "$IGNORE_UNTIL" ]] 2>/dev/null; then
    exit 0
  fi
fi

# --- load config (with defaults) ---
WARN_PERCENT=80
PAUSE_PERCENT=95
MAX_TOKENS=200000

if command -v jq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
  W=$(jq -r '.warn_at_percent // empty' "$CONFIG_FILE" 2>/dev/null)
  P=$(jq -r '.pause_at_percent // empty' "$CONFIG_FILE" 2>/dev/null)
  M=$(jq -r '.max_context_tokens // empty' "$CONFIG_FILE" 2>/dev/null)
  [[ -n "$W" ]] && WARN_PERCENT="$W"
  [[ -n "$P" ]] && PAUSE_PERCENT="$P"
  [[ -n "$M" ]] && MAX_TOKENS="$M"
fi

# --- get transcript path ---
TRANSCRIPT=$(printf '%s' "$STDIN" | jq -r '.transcript_path // empty' 2>/dev/null) || bail
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && bail

# --- read current token count ---
command -v jq &>/dev/null || bail
CURRENT_TOKENS=$(jq -rs \
  '[.[] | select(.type == "assistant") | .message.usage.input_tokens] | last // 0' \
  "$TRANSCRIPT" 2>/dev/null) || bail
[[ "$CURRENT_TOKENS" =~ ^[0-9]+$ ]] || bail

# --- compute percentage (integer math) ---
PERCENT=$(( CURRENT_TOKENS * 100 / MAX_TOKENS ))

# --- below warn: silent pass ---
if [[ "$PERCENT" -lt "$WARN_PERCENT" ]]; then
  exit 0
fi

# --- at or above pause threshold: block ---
if [[ "$PERCENT" -ge "$PAUSE_PERCENT" ]]; then
  printf '{"decision":"block","reason":"Context window is at %d%% (%d/%d tokens). Tool call blocked to prevent degraded output. Run /compact to compress history, finish the current task, or run /pause-ignore to bypass for a session."}\n' \
    "$PERCENT" "$CURRENT_TOKENS" "$MAX_TOKENS"
  exit 2
fi

# --- between warn and pause: inject context, allow tool ---
printf '{"additionalContext":"[pause-claude-code] Context window at %d%% (%d/%d tokens, warn threshold %d%%). Consider running /compact or wrapping up soon to avoid hitting the pause threshold at %d%%."}\n' \
  "$PERCENT" "$CURRENT_TOKENS" "$MAX_TOKENS" "$WARN_PERCENT" "$PAUSE_PERCENT"
exit 0
