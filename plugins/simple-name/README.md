# simple-name

Auto-renames every new session to `{repo}: {MM/DD}-{hash}` on startup — no more "General Session" or a wall of unnamed tabs.

Example: `claude-skills: 06/30-mr0jd4j7`

## Install

```bash
./plugins/simple-name/install.sh
```

Restart Claude Code. That's it — it's a `SessionStart` hook, nothing to configure or invoke.

## Uninstall

```bash
./plugins/simple-name/uninstall.sh
```
