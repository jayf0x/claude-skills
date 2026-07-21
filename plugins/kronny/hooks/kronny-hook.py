#!/usr/bin/env python3
"""Kronny PreToolUse hook — auto-approves tool calls during active windows.

Reads state from KRONNY_STATE_FILE (env) or ~/.claude/kronny/state.json.
State schema:
  {"expires_at": <unix_ts>, "pattern": "<glob>", "notified": <bool>,
   "session_id": "<uuid>"}

The window only applies to the session that created it — the hook compares
state["session_id"] against the session_id Claude Code passes on stdin, so a
window opened in one session can't leak approval to another running session.

Output (stdout, JSON):
  {"hookSpecificOutput": {..., "permissionDecision": "allow"}}
                                     — inside active window, session+pattern matched
  {"additionalContext": "..."}      — window just expired (once only)
  (empty)                           — no active window / session/pattern mismatch

Always exits 0 — must never crash Claude Code.
"""
import fnmatch
import json
import os
import sys
import time

_DEFAULT_STATE_FILE = os.path.expanduser("~/.claude/kronny/state.json")
STATE_FILE = os.environ.get("KRONNY_STATE_FILE", _DEFAULT_STATE_FILE)


def _load_state():
    if not os.path.exists(STATE_FILE):
        return None
    with open(STATE_FILE) as f:
        return json.load(f)


def _save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)


def _matches(pattern, tool_name, tool_input):
    if pattern == "*":
        return True
    # Non-wildcard patterns are bash-command globs — only match the Bash tool.
    if tool_name != "Bash":
        return False
    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
    return fnmatch.fnmatch(command, pattern)


def main():
    try:
        raw = sys.stdin.read()
        tool_call = json.loads(raw) if raw.strip() else {}
    except Exception:
        sys.exit(0)

    try:
        state = _load_state()
    except Exception:
        sys.exit(0)

    if state is None:
        sys.exit(0)

    try:
        expires_at = int(state.get("expires_at", 0))
        pattern = state.get("pattern", "*")
        notified = bool(state.get("notified", False))
        now = int(time.time())

        if now >= expires_at:
            if not notified:
                state["notified"] = True
                _save_state(state)
                print(json.dumps({
                    "additionalContext": "[kronny] Auto-approve window expired."
                }))
            sys.exit(0)

        # Strict equality (not "if session_id and ...") — a window written
        # without a session_id (e.g. CLAUDE_CODE_SESSION_ID unset when /kronny
        # ran) must not silently become global. Every session must match to
        # get auto-approved, including matching on missing session_id.
        session_id = state.get("session_id", "")
        call_session_id = tool_call.get("session_id", "")
        if session_id != call_session_id:
            sys.exit(0)

        tool_name = tool_call.get("tool_name", "")
        tool_input = tool_call.get("tool_input", {})

        if _matches(pattern, tool_name, tool_input):
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "allow",
                    "permissionDecisionReason": "kronny auto-approve window",
                }
            }))

    except Exception:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
