# safe-pause

Context-window and usage guardian. Warns at 80% context usage, blocks at 95% — and warns/blocks based on your Claude.ai subscription usage (`five_hour` / `seven_day`) once configured. Prevents Claude from dying mid-task on a long run.

Requires the bundled Chrome extension + local bridge server, plus one manual credential step — running `install.sh` alone is not enough.

## Install

```bash
./plugins/safe-pause/install.sh
```

Requires `node` (>=18), `jq`, and `curl`. This registers the MCP server + `PreToolUse` hook in `~/.claude/settings.json` and writes default config to `~/.claude/safeclaude/config.json`.

Then, restart Claude Code / Claude Desktop and finish setup:

1. **Get your credentials** — open [claude.ai](https://claude.ai), then in DevTools:
   - Application → Cookies → `claude.ai` → copy the `sessionKey` cookie
   - Network → any `/api/organizations/...` request → copy the org UUID from the URL
2. **Provide them**, either:
   - Ask Claude: `Use set_credentials with org_id=... and session_key=...`
   - Or edit `~/.claude/safeclaude/config.json` directly

## Use

```
/pause-ignore [duration]   # bypass checks temporarily
```

## Uninstall

```bash
./plugins/safe-pause/uninstall.sh
```
