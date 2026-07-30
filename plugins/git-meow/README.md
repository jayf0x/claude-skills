# git-meow

Attributes git commits to a configurable non-human co-pilot (a cat, a dog, whatever persona you set) instead of you or Claude — in any repo, no per-repo setup. Fires automatically whenever Claude is about to commit, or explicitly via `/git-meow`.

**Enforced, not just requested:** install sets a global git hook that rejects plain `git commit` everywhere on this machine — only `scripts/commit.sh` (which the skill/command run) can commit. This closes the gap where an LLM simply forgets to use the skill on a long task; the rejection comes from git itself.

## Install

```bash
./plugins/git-meow/install.sh
```

This installs the skill, wrapper scripts, a `commit-msg` + `pre-commit` git hook pair, the `/git-meow` command, and sets `git config --global core.hooksPath` to point at those hooks — globally, in every repo. Restart Claude Code if it was already running.

**Then set the persona** (required before first use): edit the identity block near the top of `~/.claude/skills/git-meow/SKILL.md`:

```
name: ...
email: ...
github_username: ...
```

Everything else — voice, personality, examples — lives in that same file; edit directly, no separate config.

### About the global hook gate

`core.hooksPath` is a single value per git config scope. Setting it globally means it *replaces* `.git/hooks` — and any repo-local hooksPath a tool like husky, the `pre-commit` framework, or lefthook set — in every repo on this machine, for as long as git-meow is installed. If a repo relies on its own hooks (lint-staged, commit linting, etc.), those stop running while this is active. `install.sh` warns if it's overriding an existing global `core.hooksPath` and saves the previous value so `uninstall.sh` can restore it. Repo-local hook overrides set *after* install (e.g. running `npm install` triggers a fresh husky install) aren't tracked and will win over this gate in that one repo — that's the one bypass this doesn't catch.

`scripts/commit.sh` also still swaps in the persona's git identity, and this same hooks dir, for the *current* repo for the duration of each wrapped commit — that's unchanged, and covers the repo-local-override case for legitimate git-meow commits.

## Optional: also push/PR as the persona

By default only the commit *author* changes — pushes and `gh pr create` still authenticate as you. To also push as the persona's own GitHub account:

```bash
~/.claude/skills/git-meow/scripts/push-account-install.sh
```

This requires the `gh` CLI and a second, already-authenticated `gh` account for the persona (`gh auth login --hostname github.com` will offer to add one if you're already logged in as yourself). It's global to the `gh` CLI — affects pushes from every repo, not just this one — until reverted:

```bash
~/.claude/skills/git-meow/scripts/push-account-uninstall.sh
```

## Use

```
/git-meow     # commit staged changes as the configured persona
```

Or just ask Claude to commit normally — it fires automatically. If something runs plain `git commit` anyway, git rejects it with a message pointing back to `commit.sh`.

## Uninstall

```bash
./plugins/git-meow/uninstall.sh
```

Restores your previous global `core.hooksPath` (or unsets it if none existed) before removing the skill files.

(Run `push-account-uninstall.sh` first if you installed the optional push-account step.)
