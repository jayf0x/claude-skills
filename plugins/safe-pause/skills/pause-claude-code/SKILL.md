---
name: safe-pause
description: >
  Pauses Claude Code when subscription usage (five_hour or seven_day utilization) 
  crosses a configured threshold. Prevents burning remaining quota mid-task.
  Activate with /pause-ignore to bypass temporarily.
---

# safe-pause

Watches your Claude.ai **subscription usage** (not context window) and blocks tool 
calls when utilization crosses a threshold.

## Architecture

```
claude.ai page
  └─ Chrome extension (content.js)
       └─ extracts org ID from window.DD_RUM
            └─ background.js polls /api/organizations/{orgId}/usage every 60s
                 └─ POSTs to usage-server.py on localhost:2999
                      └─ writes ~/.claude/safeclaude/usage.json
                           └─ PreToolUse hook reads it → warn/block
```

## Install

```bash
./install.sh
```

Then load the extension in Claude Code:
1. Open **Extensions → Install unpacked extensions...**
2. Select `~/.claude/safeclaude/extension/`

Visit `https://claude.ai` once to trigger org ID extraction.

## Commands

- `/pause-ignore` — suppress checks for 5 hours (default)
- `/pause-ignore 2h` — suppress for 2 hours
- `/pause-ignore 30m` — suppress for 30 minutes

## Config

Edit `~/.claude/safeclaude/config.json`:

```json
{
  "warn_at_percent": 75,
  "pause_at_percent": 90,
  "server_port": 2999
}
```

## Manual usage fetch

If the bridge server is not running, fetch usage manually:

```js
// In claude.ai browser console:
const orgId = window.DD_RUM?.getUser()?.organization_id;
fetch(`/api/organizations/${orgId}/usage`).then(r => r.json()).then(console.log);
```

Or via curl (requires valid session cookie):
```bash
curl -s "http://127.0.0.1:2999/usage" | jq '{five_hour: .five_hour.utilization, seven_day: .seven_day.utilization}'
```

## Uninstall

```bash
./uninstall.sh
```
