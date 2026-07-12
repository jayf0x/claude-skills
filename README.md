# Trial Skills marketplace

A repo for skills I test. Most-used skills get their own repo, like [kronny](https://github.com/jayf0x/kronny).

## Install

<!-- INSTALL:START -->
```bash
git clone https://github.com/jayf0x/claude-skills
cd claude-skills

# all at once
./install.sh

# or one at a time
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

## Skills

### 🏷 simple-name — auto-rename sessions

Every new session is renamed to `{repo}: {MM/DD}-{hash}` at startup. No more "General Session" or 200 unnamed tabs.

Example: `claude-skills: 06/30-mr0jd4j7`

Implemented as a `SessionStart` hook — fires automatically, no commands needed.

---

### 🦆 silicon-duck — always-on clarity rater

Rates every conversation before Claude replies using a three-factor **CIP score** (Constraints / Intent / Provenance, 1–5). Catch underspecified prompts before they waste a whole run.

```
/duck disable   # silence it
/duck enable    # bring it back
```

---

### ⏱ kronny — time-limited auto-approve windows

Pre-authorize tool calls for a fixed window so Claude can work uninterrupted.

```
/kronny              # approve everything for 5 min
/kronny 15           # 15-minute window
/kronny 15 "gh *"    # only commands matching "gh *"
/kronny -1           # 24-hour window
```

`PreToolUse` hook — zero restarts, zero config files.

---

### 🛑 safe-pause — context-window guardian

Warns at 80% context usage, blocks at 95%. Prevents Claude from dying mid-task on a long run.

Requires the bundled Chrome extension + local bridge server.

---

### 📋 plan-next — session continuity

`/plan` picks up exactly where you left off. Reads your plan file and session history, auto-detects the next stage.

```
/plan            # resume next stage
/plan 3          # jump to stage 3
/plan deploy     # jump to a named stage
```

---

## Uninstall

<!-- UNINSTALL:START -->
```bash
./plugins/kronny/uninstall.sh
./plugins/local-commands/uninstall.sh
./plugins/plan-next/uninstall.sh
./plugins/safe-pause/uninstall.sh
./plugins/silicon-duck/uninstall.sh
./plugins/simple-name/uninstall.sh
```
<!-- UNINSTALL:END -->
