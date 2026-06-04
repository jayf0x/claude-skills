#!/usr/bin/env python3
"""Kronny CLI — set time-limited auto-approve windows for Claude Code.

Usage:
  kronny.py              # allow everything for 5 minutes (default)
  kronny.py 5            # same
  kronny.py 15 "gh *"   # allow bash commands matching "gh *" for 15 minutes
  kronny.py -1           # allow everything for 24 hours

State dir: KRONNY_STATE_DIR (env) or ~/.claude/kronny/
"""
import json
import os
import sys
import time
from datetime import datetime

_DEFAULT_STATE_DIR = os.path.expanduser("~/.claude/kronny")
STATE_DIR = os.environ.get("KRONNY_STATE_DIR", _DEFAULT_STATE_DIR)
STATE_FILE = os.path.join(STATE_DIR, "state.json")


def main():
    args = sys.argv[1:]

    minutes = 5
    pattern = "*"

    if args:
        try:
            minutes = int(args[0])
        except ValueError:
            print(
                f"Error: first argument must be an integer (minutes), got: {args[0]!r}",
                file=sys.stderr,
            )
            sys.exit(1)
        if len(args) > 1:
            pattern = args[1]

    if minutes == -1:
        minutes = 24 * 60
    elif minutes <= 0:
        print(
            f"Error: minutes must be a positive integer or -1 (24h), got: {minutes}",
            file=sys.stderr,
        )
        sys.exit(1)

    now = int(time.time())
    expires_at = now + minutes * 60

    os.makedirs(STATE_DIR, exist_ok=True)
    state = {"expires_at": expires_at, "pattern": pattern, "notified": False}
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)

    until = datetime.fromtimestamp(expires_at).strftime("%H:%M:%S")
    if pattern == "*":
        print(f"[kronny] Auto-approving ALL tools until {until} ({minutes}m).")
    else:
        print(f"[kronny] Auto-approving bash '{pattern}' until {until} ({minutes}m).")


if __name__ == "__main__":
    main()
