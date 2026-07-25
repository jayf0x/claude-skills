# plan-next

Session-continuity skill. `/plan` reads your plan file and past session history, auto-detects the next stage, and picks up exactly where you left off — no retyping context.

## Install

```bash
./plugins/plan-next/install.sh
```

Requires `python3`. Restart Claude Code after installing.

## Use

```
/plan            # resume next stage
/plan 3          # jump to stage 3
/plan deploy     # jump to a named stage
```

## Uninstall

```bash
./plugins/plan-next/uninstall.sh
```
