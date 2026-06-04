# jayf0x/skills

Claude Code skill marketplace — productivity upgrades you install once and forget about.

## Add marketplace

```
/plugin marketplace add @jayf0x/skills
```

Then install any skill:

```bash
/plugin install silicon-duck
/plugin install kronny
/plugin install safe-pause
/plugin install plan-next
```

---

## Skills

### 🦆 SiliconDuck — always-on clarity rater

Rates every conversation before Claude replies using a three-factor **CIP score** (Constraints / Intent / Provenance, 1–5). Catch underspecified prompts before they waste a whole run.

```
/duck disable   # silence it
/duck enable    # bring it back
```

No configuration needed — active the moment it's installed.

---

### ⏱ Kronny — time-limited auto-approve windows

Tired of approving the same tool call twenty times in a row? Kronny lets you pre-authorize tool calls for a fixed window so Claude can work uninterrupted.

```
/kronny              # approve everything for 5 min
/kronny 15           # 15-minute window
/kronny 15 "gh *"    # only commands matching "gh *" for 15 min
/kronny -1           # 24-hour window (trust mode)
```

Implemented as a `PreToolUse` hook — zero session restarts, zero config files to hand-edit.

---

### 🛑 safe-pause — context-window guardian

Warns at 80% context usage, blocks at 95%. Prevents Claude from dying mid-task on a long run and losing all its work.

Requires the bundled Chrome extension + local bridge server to read subscription utilization from the Claude.ai API.

---

### 📋 plan-next — session continuity

`/plan` picks up exactly where you left off. Reads your plan file and session history, auto-detects the next stage, and begins it — no retyping required.

```
/plan            # resume next stage
/plan 3          # jump to stage 3
/plan deploy     # jump to a named stage
```

---

## Requirements

| Skill | Requires |
|-------|----------|
| silicon-duck | nothing |
| kronny | `python3` |
| safe-pause | `jq`, Chrome extension, local bridge |
| plan-next | `python3` |

---

## Install without the marketplace

```bash
git clone https://github.com/jayf0x/skills
cd skills

# all at once
./install.sh

# or one at a time
./plugins/silicon-duck/install.sh
./plugins/kronny/install.sh
./plugins/safe-pause/install.sh
./plugins/plan-next/install.sh
```

## Uninstall

```bash
./install.sh uninstall                      # all
./install.sh uninstall kronny               # one
./plugins/silicon-duck/uninstall.sh         # direct
```
