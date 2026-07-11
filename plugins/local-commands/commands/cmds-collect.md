# /cmds-collect — dump this session's useful commands

Review the entire current session and collect shell/CLI commands worth remembering, then write them to a dated markdown file. This is a raw dump — do NOT read, compare with, or dedupe against existing files.

## What to include

Only commands that are **non-obvious or system-specific** — things a fresh agent would not guess on the first try:

- Commands that needed a specific tool variant (e.g. `bun` instead of `npm`, `gsed` instead of `sed`)
- Test/build invocations that needed extra flags, env vars, or a specific node/python version
- Multi-step incantations that took trial and error to get right
- Project- or machine-specific setup, ports, paths, services

## What to exclude

- Standard commands any agent knows (`git status`, `ls`, `npm install`)
- Commands so case-specific they'll never recur (one-off greps, debugging a single typo)
- Commands that failed and were abandoned

## Output

Write to `~/.claude/cache/local-commands/cmd-{YYYY-MM-DD-HHMMSS}.md` (create the directory if needed; use `date +%Y-%m-%d-%H%M%S` for the timestamp so multiple collects never collide).

Format each entry as:

```markdown
## <short title>
Context: <one line: when/why this is needed>
```bash
<the command>
```
```

If the session contains nothing worth collecting, say so and write nothing. Finish by telling the user the file path and how many commands were captured.
