# commit-mauw

Attributes git commits to a configurable non-human co-pilot (a cat, a dog, whatever persona you set) instead of you or Claude — in any repo, no per-repo setup. Fires automatically whenever Claude is about to commit, or explicitly via `/commit-mauw`.

## Install

```bash
./plugins/commit-mauw/install.sh
```

This installs the skill, wrapper scripts, a `commit-msg` git hook, and the `/commit-mauw` command globally. Restart Claude Code if it was already running.

**Then set the persona** (required before first use): edit the identity block near the top of `~/.claude/skills/commit-mauw/SKILL.md`:

```
name: ...
email: ...
github_username: ...
```

Everything else — voice, personality, examples — lives in that same file; edit directly, no separate config.

## Optional: also push/PR as the persona

By default only the commit *author* changes — pushes and `gh pr create` still authenticate as you. To also push as the persona's own GitHub account:

```bash
~/.claude/skills/commit-mauw/scripts/push-account-install.sh
```

This requires the `gh` CLI and a second, already-authenticated `gh` account for the persona (`gh auth login --hostname github.com` will offer to add one if you're already logged in as yourself). It's global to the `gh` CLI — affects pushes from every repo, not just this one — until reverted:

```bash
~/.claude/skills/commit-mauw/scripts/push-account-uninstall.sh
```

## Use

```
/commit-mauw     # commit staged changes as the configured persona
```

Or just ask Claude to commit normally — it fires automatically.

## Uninstall

```bash
./plugins/commit-mauw/uninstall.sh
```

(Run `push-account-uninstall.sh` first if you installed the optional push-account step.)
