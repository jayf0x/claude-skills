---
name: kronny
description: >
  Activated via the /kronny slash command. Use when the user says /kronny.
---

Mechanical, not conversational. No understanding of args needed — just forward.

The window is scoped to the session that runs `/kronny` (via `CLAUDE_CODE_SESSION_ID`)
— it won't auto-approve tool calls in other concurrently-running sessions.

- `/kronny [args]` → run `python3 ~/.claude/kronny/kronny.py [args]` via Bash,
  unconditionally, before anything else in the message. Use only the first
  line of args; ignore anything after it (separate task, not kronny's).
- `/kronny status` or `/kronny ttl` → show time left on the current window.

Show only the CLI's output line. No commentary unless it errors.
