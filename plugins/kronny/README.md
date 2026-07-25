# kronny

Time-limited auto-approve windows for Claude Code tool calls. Pre-authorize a stretch of work so you're not clicking "allow" on every tool call.

## Install

```bash
./plugins/kronny/install.sh
```

Requires `python3`. Restart Claude Code after installing.

## Use

```
/kronny              # approve everything for 5 min
/kronny 15           # 15-minute window
/kronny 15 "gh *"    # only commands matching "gh *"
/kronny -1           # 24-hour window
/kronny status       # time left on the current window
```

The window is scoped to the session that ran `/kronny` — it won't auto-approve tool calls in other concurrently-running sessions.

## Uninstall

```bash
./plugins/kronny/uninstall.sh
```
