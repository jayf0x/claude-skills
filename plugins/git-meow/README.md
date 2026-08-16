# git-meow

Attributes git commits to a configurable non-human co-pilot (a cat, a dog, whatever persona you set) instead of you or Claude — in any repo, no per-repo setup. Fires automatically whenever Claude is about to commit, or explicitly via `/git-meow`.

**Enforced, not just requested:** install sets a global git hook that rejects plain `git commit` run by an AI agent — only `scripts/commit.sh` (which the skill/command run) can commit. This closes the gap where an LLM simply forgets to use the skill on a long task; the rejection comes from git itself. The gate only fires when `CLAUDECODE=1` is set in the environment (true for every command Claude Code runs, absent for a human's own terminal or GUI commits), so it never blocks you — only the agent.

## Install

```bash
./plugins/git-meow/install.sh
```

This installs the skill, wrapper scripts, a `commit-msg` + `pre-commit` git hook pair, the `/git-meow` command, and sets `git config --global core.hooksPath` to point at those hooks — globally, in every repo. Restart Claude Code if it was already running.

**Then set the persona** (required before first use) — if you ran `install.sh` yourself in a terminal, it notices no persona is configured yet and offers to launch this for you immediately; otherwise (or to redo it later) run it directly:

```bash
~/.claude/skills/git-meow/scripts/setup-persona.sh
```

It's interactive and checks its own work as it goes:
- Asks if the persona has its own GitHub account. If so, it logs it into `gh` (a normal browser device-code flow), *verifies* the login actually matches the username you gave (catches typos / wrong account), then suggests a name and a **verified** email pulled from that account's own GitHub profile — you approve or edit, rather than typing an email that might not even be verified (an unverified email silently never shows up on the persona's contribution graph, so this is the check that actually matters).
- If it has no GitHub account, falls back to typing name/email by hand — commits still get attributed, just no push/PR identity.
- Writes the result into the identity block near the top of `~/.claude/skills/git-meow/SKILL.md` (still the only place identity lives — edit it directly any time instead, if you prefer) and reads it back to confirm what was actually saved.
- If you opted into a GitHub account, offers to also switch `gh`'s active account to it (see below), explaining upfront that this is global before doing it.

If `install.sh` runs unattended (e.g. Claude itself ran it, not you at a terminal) it skips auto-launching this — an interactive `gh auth login` prompt would just hang with no one to answer it — and prints a loud warning instead, since `commit.sh` otherwise fails *silently*: with no persona configured it just falls back to committing as you, no error. Claude is instructed to notice that and offer to run `setup-persona.sh` itself rather than leaving you to find this file.

Voice, personality, and examples also live in `SKILL.md`; edit directly, no separate config.

### About the global hook gate

`core.hooksPath` is a single value per git config scope. Setting it globally means it *replaces* `.git/hooks` — and any repo-local hooksPath a tool like husky, the `pre-commit` framework, or lefthook set — in every repo on this machine, for as long as git-meow is installed. If a repo relies on its own hooks (lint-staged, commit linting, etc.), those stop running while this is active. `install.sh` warns if it's overriding an existing global `core.hooksPath` and saves the previous value so `uninstall.sh` can restore it. Repo-local hook overrides set *after* install (e.g. running `npm install` triggers a fresh husky install) aren't tracked and will win over this gate in that one repo — that's the one bypass this doesn't catch.

`scripts/commit.sh` also still swaps in the persona's git identity, and this same hooks dir, for the *current* repo for the duration of each wrapped commit — that's unchanged, and covers the repo-local-override case for legitimate git-meow commits.

## Optional: also push/PR as the persona

By default only the commit *author* changes — pushes and `gh pr create` still authenticate as you. `setup-persona.sh` offers to set this up (logging the persona into `gh`, then running the script below); to redo it standalone:

```bash
~/.claude/skills/git-meow/scripts/push-account-install.sh
```

Requires the `gh` CLI and a second, already-authenticated `gh` account for the persona. It's global to the `gh` CLI — affects pushes from every repo, not just this one — until reverted:

```bash
~/.claude/skills/git-meow/scripts/push-account-uninstall.sh
```

**The persona also needs push access on the actual repo(s)** before this does anything useful — being the active `gh` account doesn't grant permissions. Being the commit *author* never required this (that's just text in a commit), but pushing does:

```bash
~/.claude/skills/git-meow/scripts/grant-repo-access.sh
```

Asks whether to invite the persona as a collaborator on just the repo you're standing in, or on every local repo you own under a directory you pick — then accepts the invite(s) as the persona so there's no dangling manual step. Not run automatically by `setup-persona.sh`; call it whenever you actually hit a repo the persona can't push to.

## Use

```
/git-meow     # commit staged changes as the configured persona
```

Or just ask Claude to commit normally — it fires automatically. If Claude runs plain `git commit` anyway, git rejects it with a message pointing back to `commit.sh`. Your own commits — terminal, GitHub Desktop, any other tool — are never affected.

## Uninstall

```bash
./plugins/git-meow/uninstall.sh
```

Restores your previous global `core.hooksPath` (or unsets it if none existed) before removing the skill files.

(Run `push-account-uninstall.sh` first if you installed the optional push-account step.)
