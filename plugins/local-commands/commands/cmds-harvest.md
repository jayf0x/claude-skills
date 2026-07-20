# /cmds-harvest — mine past session transcripts for useful commands

Backfill the command cache from historical sessions, without reopening them. Session transcripts live as JSONL in `~/.claude/projects/<project-dir>/*.jsonl`; every Bash tool call is recorded there.

## Steps

1. Extract all Bash commands from every transcript for this project, pre-filtered mechanically before any judgement:

```bash
python3 ~/.claude/cache/local-commands/scripts/extract-commands.py --all --sort freq > /tmp/harvested-commands.txt
```

   (Use `--every-project` instead of `--all` to mine every project's transcripts, not just this one.) This mechanically drops noise (too short/long, common commands like `ls`/`git status`, multi-line heredocs) and merges exact duplicates with a repeat count — same filtering `/cmds-collect` uses, just pointed at every transcript instead of one.
2. Read the result (in chunks if large — it's sorted most-repeated first). Since you weren't present for these sessions, infer context from the command itself. Apply the same judgement as `/cmds-collect`: keep only non-obvious or system-specific commands (tool variants like bun-over-npm, flags/env vars that took trial and error, machine-specific setup). Repeat count is a usefulness signal, but a command used once can still be a keeper.
3. Write survivors to `~/.claude/cache/local-commands/cmd-harvest-{YYYY-MM-DD}.md`, same per-entry format as `/cmds-collect` (title, one-line context, fenced command). If context is unclear from the command alone, a short guess is fine.
4. Report: transcripts scanned, raw commands found, entries kept, output path. Suggest running `/cmds-compress` next.

Run this once for backfill; after that, `/cmds-collect` per session is enough.
