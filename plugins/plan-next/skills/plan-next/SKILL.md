---
name: plan-next
description: >
  Smart session-continuation skill. Use this skill immediately whenever the user
  types /plan, /plan next, /plan <stage>, or says anything like "continue from
  last session", "what's next in the plan", "pick up where we left off", or
  "start stage X". Reads ~/.claude/projects/ session history and the repo's
  plan file to auto-detect the next stage and begin it — no retyping required.
---

# plan-next

Automates the "start the next session" prompt by reading your session history
and plan file to figure out exactly where you left off.

## How it works

1. Run the context script to read session history + plan file
2. Analyze what stage was last completed
3. Determine what comes next (or use the explicit stage argument)
4. Begin that stage immediately

## Step 1 — Run the context script

```bash
bash "${HOME}/.claude/skills/plan-next/scripts/plan-context.sh" "$ARGUMENTS"
```

Run this and read its full output before doing anything else.

The script outputs:
- **PROJECT_ROOT** — confirmed repo path
- **REQUESTED_STAGE** — the argument passed (`next`, `a`, `b`, `c`, `1`, `2`, …)
- **PLAN FILE** — full content of plan.md / CLAUDE.md / stages.md / TODO.md
- **RECENT GIT LOG** — last 8 commits
- **SESSION HISTORY** — first and last messages from the 3–5 most recent sessions

## Step 2 — Determine the next stage

Use this decision tree:

### If REQUESTED_STAGE is an explicit label (e.g. `a`, `b`, `c`, `2`, `III`)
→ Skip detection. Start that stage directly.

### If REQUESTED_STAGE is `next` (default)
Look at the session history and plan file together:

1. **Find the plan's stage list** — scan the plan file for patterns like:
   - `## Stage A` / `## Stage B`
   - `# Phase 1` / `# Phase 2`
   - `- [ ] Step 1` / `- [x] Step 1` (checkboxes)
   - `**Stage A:**` or `Stage A:` inline

2. **Find the last completed stage** — from the most recent session's closing turns:
   - Look for phrases like "Stage A complete", "finished phase 1", "done with step 2"
   - Look for the opening prompt of the most recent session (e.g. "Complete Stage B from plan.md")
   - Cross-reference with recent git log (commits often name the stage)

3. **Infer the next stage** — the one after the last completed one.

4. **Confirm with one line** before starting:
   ```
   Last completed: Stage B  →  Starting: Stage C
   ```
   Then begin immediately (no waiting for user confirmation unless ambiguous).

### If context is ambiguous
State what you found and ask one targeted question:
```
I found sessions but can't clearly identify the last stage.
The plan has: Stage A, Stage B, Stage C.
Recent session opened with: "..."
Which stage should I start?
```

## Step 3 — Begin the stage

Once the target stage is identified:

1. Re-read the plan file section for that stage carefully
2. Follow exactly what it specifies — tools to use, files to touch, constraints
3. Do not summarize the plan back to the user; just execute it
4. When done, end with a clear completion marker like:
   ```
   ✓ Stage C complete. Ready for /plan next to begin Stage D.
   ```

---

## Supported plan file formats

The script auto-detects the first match in this order:
`plan.md` → `PLAN.md` → `Plan.md` → `stages.md` → `STAGES.md` → `CLAUDE.md` → `claude.md` → `TODO.md` → `todo.md`

Common stage patterns that are recognized:
```markdown
## Stage A — Title        # Most explicit, preferred
## Phase 1: Title
- [ ] Step 1              # Checkbox lists (unchecked = not done)
- [x] Step 1              # Checked = done
**Step 1:**               # Bold inline
```

---

## Notes

- **Agent sessions excluded** — the script skips `agent-*.jsonl` files, focusing
  on your top-level sessions only.
- **No plan file?** — if no plan file is found, the script still outputs session
  history. You can read it and ask the user to clarify, or run `/plan` after
  creating a `plan.md`.
- **New project** — if no session history exists yet, say so clearly and ask
  the user which stage to start.
- **Path encoding** — Claude encodes project paths as `/Users/you/myapp` →
  `-Users-you-myapp`. If the project dir isn't found, report the expected path
  so the user can debug.
