# /cmds-collect — dump this session's useful commands

Collect shell/CLI commands worth remembering from the current session, then write them to a dated markdown file. This is a raw dump — do NOT read, compare with, or dedupe against existing files.

## Step 0: get the candidate list mechanically

Do NOT recall commands from memory or by re-reading the transcript yourself — that's error-prone (mistyped flags, invented commands). Instead run:

```bash
python3 ~/.claude/cache/local-commands/scripts/extract-commands.py
```

This prints one candidate command per line (tab-prefixed with an occurrence count), mechanically extracted and pre-filtered (length, common noise commands, multi-line scripts) from this session's own transcript. If it prints nothing after the `#` summary line, there are no candidates — skip straight to "When to write nothing" below.

For each candidate, use your memory of the session (why the command was run, what problem it solved) to judge it against the bar below — the script does extraction, you do judgment.

## The bar: would this help in a *different* project?

The test is not "was this useful today" — almost everything is. The test is whether the **technique** transfers once you strip today's project name out of it. If the only thing worth saving is "this app's binary is called X" or "this repo's script is called Y," that's not a command worth collecting — it's a fact about one repo that will be stale or irrelevant elsewhere.

Concretely:

- **Package.json/Makefile script aliases are not commands.** `bun run verify`, `npm run kill`, `make build` teach nothing by themselves — the agent can already read package.json. Only collect what's *inside* the alias, and only if those underlying flags are themselves non-obvious (e.g. `tauri build --debug --bundles app` to skip DMG bundling because `hdiutil` fails in sandboxed shells — the flag choice is the non-obvious part, not the fact that it's wrapped in a script).
- **Machine/tool-chain facts generalize; project facts don't.** "`python3 -c 'import Quartz'` fails here, use Swift/CoreGraphics instead" is a machine fact — keep it, but drop the specific display-listing code unless the technique itself is the point. "This app persists state at `~/Library/Application Support/<AppName>/db`" is a project fact — drop it, even if the SQL is well-written.
- **Shell/tool gotchas generalize; the file/pattern you hit it on doesn't.** "zsh glob-expands unquoted `--include=*.tsx` and errors" is worth keeping. Which directory you were grepping is not — strip it or replace it with a placeholder.
- When a command is worth keeping but names this project's paths, binaries, or identifiers, **abstract them** into placeholders (`<binary-name>`, `<project-root>`, `<db-path>`) rather than dropping the technique entirely.

## What to exclude

- Standard commands any agent knows (`git status`, `ls`, `npm install`)
- Package/Makefile script aliases whose name is the only non-obvious part (see above)
- Commands so case-specific they'll never recur (one-off greps, debugging a single typo)
- Facts about this specific app/repo (its binary name, its DB schema, its file layout) that don't teach a reusable technique
- Commands that failed and were abandoned

## When to write nothing

If a session was spent entirely inside one project using that project's own scripts and conventions, the honest output is often **zero entries** — not a padded list of that project's tooling. Don't strain to find something to save. An empty result is a correct result; say so and don't create the file.

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
