# Trial Skills marketplace

A repo for skills I test. Most-used skills get their own repo, like [kronny](https://github.com/jayf0x/kronny).

![kronny](./assets/preview-kronny.png)

## Install

One-liner (all plugins):
```bash
curl -fsSL https://raw.githubusercontent.com/jayf0x/claude-skills/main/install.sh | bash
```

One plugin:
```bash
curl -fsSL https://raw.githubusercontent.com/jayf0x/claude-skills/main/install.sh | bash -s -- kronny
```

<!-- INSTALL:START -->
```bash
git clone https://github.com/jayf0x/claude-skills
cd claude-skills

# all at once
./install.sh

# or one at a time
./plugins/commit-mauw/install.sh
./plugins/kronny/install.sh
./plugins/local-commands/install.sh
./plugins/plan-next/install.sh
./plugins/safe-pause/install.sh
./plugins/silicon-duck/install.sh
./plugins/simple-name/install.sh
```
<!-- INSTALL:END -->

Restart Claude Code after installing.

### Via marketplace (Claude Code desktop/web only)

```
/plugin marketplace add @jayf0x/skills
/plugin install simple-name
```

> `/plugin` is not available in all environments — use the bash install above if that command isn't recognized.

---

## Plugins

Each plugin has its own README with install/uninstall details — linked below.

<!-- PLUGINS:START -->
| Plugin | Description | Install | Uninstall |
| --- | --- | --- | --- |
| [commit-mauw](./plugins/commit-mauw/README.md) | Attributes git commits to a configurable non-human co-pilot persona (cat, dog, or your own), in its voice, in every repo. Edit the identity block in the installed SKILL.md directly to customize. | `./plugins/commit-mauw/install.sh` | `./plugins/commit-mauw/uninstall.sh` |
| [kronny](./plugins/kronny/README.md) | Grants time-limited auto-approve windows via a PreToolUse hook. /kronny [minutes] ["pattern"] — no session restart required. | `./plugins/kronny/install.sh` | `./plugins/kronny/uninstall.sh` |
| [local-commands](./plugins/local-commands/README.md) | Collect non-obvious shell commands from sessions (/cmds-collect) and compress them into a globally-active cheat-sheet skill (/cmds-compress). | `./plugins/local-commands/install.sh` | `./plugins/local-commands/uninstall.sh` |
| [plan-next](./plugins/plan-next/README.md) | Smart session-continuation skill. Invoke /plan or /plan-next to auto-detect the next stage from your plan file and session history, and begin it immediately — no retyping required. Supports /plan <stage> to jump to a specific stage. | `./plugins/plan-next/install.sh` | `./plugins/plan-next/uninstall.sh` |
| [safe-pause](./plugins/safe-pause/README.md) | Warns and blocks tool calls when Claude.ai subscription utilization (five_hour or seven_day) crosses configurable thresholds. Requires the bundled Chrome extension + local bridge server to read actual usage from the API. | `./plugins/safe-pause/install.sh` | `./plugins/safe-pause/uninstall.sh` |
| [silicon-duck](./plugins/silicon-duck/README.md) | Always-on rubber duck that prepends a CIP clarity score (Constraints / Intent / Provenance, 1–5 each) before every reply so you can track how well-specified the conversation is. | `./plugins/silicon-duck/install.sh` | `./plugins/silicon-duck/uninstall.sh` |
| [simple-name](./plugins/simple-name/README.md) | Auto-renames sessions to {repo}: {MM/DD}-{hash} on session start. | `./plugins/simple-name/install.sh` | `./plugins/simple-name/uninstall.sh` |
<!-- PLUGINS:END -->

---

## Uninstall

<!-- UNINSTALL:START -->
```bash
./plugins/commit-mauw/uninstall.sh
./plugins/kronny/uninstall.sh
./plugins/local-commands/uninstall.sh
./plugins/plan-next/uninstall.sh
./plugins/safe-pause/uninstall.sh
./plugins/silicon-duck/uninstall.sh
./plugins/simple-name/uninstall.sh
```
<!-- UNINSTALL:END -->
