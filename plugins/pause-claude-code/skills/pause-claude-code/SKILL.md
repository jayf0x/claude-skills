# pause-claude-code

Pauses Claude Code before the context window fills up.

## What it does

Installs a `PreToolUse` hook that reads current token usage from the live session transcript and:
- **Warns** (injects a context message) when usage passes the warn threshold (default 80%)
- **Blocks** (denies the tool call, exit 2) when usage passes the pause threshold (default 95%)

## Install

```bash
./install.sh
```

## Uninstall

```bash
./uninstall.sh
```

## Commands

- `/pause-ignore` — suppress checks for 5 hours (default)
- `/pause-ignore 2h` — suppress for 2 hours
- `/pause-ignore 30m` — suppress for 30 minutes

## Config

Edit `~/.claude/safeclaude/config.json`:

```json
{
  "warn_at_percent": 80,
  "pause_at_percent": 95,
  "max_context_tokens": 200000
}
```
