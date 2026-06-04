---
name: kronny
description: >
  Kronny manages time-limited auto-approve windows for Claude Code tool calls.
  Activated via the /kronny slash command. When a window is active, the PreToolUse
  hook auto-approves matching tools so Claude can work without permission prompts.
  Use when the user says /kronny, asks to set an auto-approve window, or wants to
  temporarily allow tools without confirmation.
---

# Kronny — Time-Limited Auto-Approve Windows

Kronny lets you pre-authorize tool calls for a fixed duration by writing a state
file that the `kronny-hook.py` PreToolUse hook reads on every tool call.

## Slash command

```
/kronny              # allow everything for 5 minutes
/kronny 5            # same
/kronny 15 "gh *"   # allow bash commands matching "gh *" for 15 minutes
/kronny -1           # allow everything for 24 hours
```

The command runs `python3 ~/.claude/kronny/kronny.py [args]` via the Bash tool.

## State file

`~/.claude/kronny/state.json`:
```json
{
  "expires_at": 1717500000,
  "pattern": "*",
  "notified": false
}
```

- `expires_at` — Unix timestamp when the window closes
- `pattern` — `"*"` approves all tools; any other value is a bash-command glob
  (only matches `Bash` tool calls where the command fits the glob)
- `notified` — set to `true` after the expiry notification fires (prevents repeats)

## When invoked

If the user runs `/kronny [args]`, call the CLI via Bash and show the output.
Do not add commentary unless the command fails.

If the user asks "is kronny active?" or "how long is left?", read
`~/.claude/kronny/state.json` with the Bash tool and report `expires_at` as a
human-readable time, plus the pattern.
