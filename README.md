# jayf0x/skills

Claude Code skill marketplace. Two skills — install them all or pick one.

## Add marketplace

```
/plugin marketplace add @jayf0x/skills
```

Then install any skill:

```
/plugin install pause-claude-code
/plugin install plan-next
```

## Skills

| Skill | What it does | Requires |
|-------|-------------|----------|
| [pause-claude-code](plugins/pause-claude-code) | Blocks tool calls when context window hits 95% (warns at 80%). Prevents mid-task session death. | `jq` |
| [plan-next](plugins/plan-next) | `/plan` resumes exactly where you left off — reads your plan file and session history to auto-detect the next stage. | `python3` |

## Install without the marketplace

Clone and run:

```bash
git clone https://github.com/jayf0x/skills
cd skills

# all at once
./install.sh

# or one at a time
./plugins/pause-claude-code/install.sh
./plugins/plan-next/install.sh
```

## Uninstall

```bash
./install.sh uninstall                     # all
./install.sh uninstall pause-claude-code   # one
./plugins/plan-next/uninstall.sh           # direct
```

## Requirements

- `bash`
- `jq` — pause-claude-code only (`brew install jq`)
- `python3` — plan-next only (standard on macOS/Linux)
