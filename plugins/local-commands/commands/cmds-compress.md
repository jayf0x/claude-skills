# /cmds-compress — compress collected commands into the active cheat sheet

Compress all collected session dumps into a single cheat sheet that a SessionStart hook injects into every future session.

## Steps

1. Read every `~/.claude/cache/local-commands/cmd-*.md` file. If there are none, stop and say so.
2. Also read the existing cheat sheet at `~/.claude/cache/local-commands/all-local-commands.md` if it exists — its entries are part of the merge, never lost.
3. For each command, decide whether it earns a place:
   - **Globally useful?** Drop commands that only made sense in one narrow situation.
   - **Duplicate?** Merge duplicates and near-duplicates into one canonical entry; keep the best-explained variant.
   - **Clean of local values?** Replace project-specific paths, repo names, ports, tokens with placeholders like `<project-root>`, `<port>`. Machine-level facts that ARE the point (e.g. "this machine uses bun") stay as-is.
4. Group surviving entries by topic (testing, package management, git/GitHub, system, etc.).
5. Write the result to `~/.claude/cache/local-commands/all-local-commands.md`. Start with a one-line title (`# Local Commands Cheat Sheet`), then the grouped entries, same per-entry format as the dumps (title, one-line context, fenced command). Keep it tight — this whole file is injected into every session's context, so every line costs tokens.
6. Delete the processed `cmd-*.md` files (only the ones you read; leave any created mid-run).
7. Report: how many entries in, how many kept, path of the cheat sheet.

A SessionStart hook injects this file at the start of every new session, so the new version is live immediately — no reload needed.
