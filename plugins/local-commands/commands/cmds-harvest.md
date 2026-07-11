# /cmds-harvest — mine past session transcripts for useful commands

Backfill the command cache from historical sessions, without reopening them. Session transcripts live as JSONL in `~/.claude/projects/<project-dir>/*.jsonl`; every Bash tool call is recorded there.

## Steps

1. Extract all Bash commands from all transcripts, pre-filtered mechanically before any judgement:

```bash
find ~/.claude/projects -name '*.jsonl' -print0 | xargs -0 cat 2>/dev/null \
  | jq -r 'select(.message.content? | type == "array")
           | .message.content[]
           | select(.type? == "tool_use" and .name? == "Bash")
           | .input.command' 2>/dev/null \
  | grep -vE '^(ls|cat|cd|pwd|echo|git (status|log|diff|add|commit|push|pull)|npm (install|test|run)|mkdir|rm|cp|mv|grep|find|which|head|tail|wc|chmod)\b' \
  | sort | uniq -c | sort -rn > /tmp/harvested-commands.txt
```

   Adjust the exclusion list as needed — the goal is dropping obviously-standard commands, not perfect filtering.
2. Read the result (in chunks if large). Apply the same judgement as `/cmds-collect`: keep only non-obvious or system-specific commands (tool variants like bun-over-npm, flags/env vars that took trial and error, machine-specific setup). Repeat count is a usefulness signal, but a command used once can still be a keeper.
3. Write survivors to `~/.claude/cache/local-commands/cmd-harvest-{YYYY-MM-DD}.md`, same per-entry format as `/cmds-collect` (title, one-line context, fenced command). Infer context from the command itself; if unclear, a short guess is fine.
4. Report: transcripts scanned, raw commands found, entries kept, output path. Suggest running `/cmds-compress` next.

Run this once for backfill; after that, `/cmds-collect` per session is enough.
