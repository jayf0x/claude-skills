#!/usr/bin/env bash
# Wraps `git push` for whatever repo you're currently in. If the persona has
# its own GitHub account configured (github_username in SKILL.md) and is
# logged into gh, this push authenticates as that account — for this one
# push only, via GH_TOKEN (git's credential helper checks it before any
# stored/active gh account). No global gh account switch, nothing to revert.
# Otherwise it's a plain `git push`, using your own credentials.
#
# Usage: same arguments as `git push`, e.g.:
#   ~/.claude/skills/git-meow/scripts/push.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "push.sh: not inside a git repo" >&2
    exit 1
}

extract_field() {
    awk -v f="$1" '
        /<!-- meow-identity/ { inblock=1; next }
        inblock && /-->/ { inblock=0 }
        inblock && $0 ~ "^"f":" {
            sub("^"f":[ \t]*", "");
            print;
            exit
        }
    ' "$SKILL_MD" 2>/dev/null
}

gh_user=""
[[ -f "$SKILL_MD" ]] && gh_user="$(extract_field github_username)"
case "$gh_user" in *REPLACE_ME*|"") gh_user="" ;; esac

if [[ -n "$gh_user" ]] && command -v gh &>/dev/null; then
    token="$(gh auth token --hostname github.com --user "$gh_user" 2>/dev/null || true)"
    if [[ -n "$token" ]]; then
        gh auth setup-git >/dev/null 2>&1 || true
        echo "push.sh: pushing as $gh_user" >&2
        GH_TOKEN="$token" git -C "$repo_root" push "$@"
        exit $?
    fi
    echo "push.sh: $gh_user isn't logged into gh here — pushing as you instead" >&2
fi

git -C "$repo_root" push "$@"
