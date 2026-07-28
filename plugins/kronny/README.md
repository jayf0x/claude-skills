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

Removes the hook registration, CLI scripts, slash command, and skill. The state
dir (`~/.claude/kronny/`) is left in place only if it still holds a state file;
the script prints the exact path to remove if you want it gone too — no other
leftovers.

## Don't mix installs

Don't run this local install alongside a marketplace-installed `kronny` plugin
(an enabled `"kronny@..."` entry in `~/.claude/settings.json`). Both register
their own command, skill, and PreToolUse hook — running both at once causes
duplicate or conflicting behavior (an agent second-guessing which CLI path is
"real", the hook firing twice, etc.). Pick one. `install.sh` checks for this
and warns if it detects a marketplace plugin still enabled.
