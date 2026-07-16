#!/usr/bin/env bash
# Wraps `git commit` for whatever repo you're currently in, temporarily
# switching git identity to the persona configured in the SKILL.md identity
# block (one directory up from this script), then restoring whatever was
# there before — regardless of outcome. Works in any repo, no per-repo setup.
#
# Usage: same arguments as `git commit`, e.g.:
#   ~/.claude/skills/commit-mauw/scripts/commit.sh -m "did a thing"
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"
HOOKS_DIR="${SCRIPT_DIR}/../githooks"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "commit.sh: not inside a git repo" >&2
    exit 1
}

extract_field() {
    awk -v f="$1" '
        /<!-- mauw-identity/ { inblock=1; next }
        inblock && /-->/ { inblock=0 }
        inblock && $0 ~ "^"f":" {
            sub("^"f":[ \t]*", "");
            print;
            exit
        }
    ' "$SKILL_MD" 2>/dev/null
}

name=""
email=""
if [[ -f "$SKILL_MD" ]]; then
    name="$(extract_field name)"
    email="$(extract_field email)"
fi

case "${name}${email}" in
    *REPLACE_ME*|"")
        name=""
        email=""
        ;;
esac

prev_name=""; prev_name_set=0
prev_email=""; prev_email_set=0
prev_hooks_path=""; prev_hooks_path_set=0
switched=0

restore() {
    if [[ "$switched" == "1" ]]; then
        if [[ "$prev_name_set" == "1" ]]; then
            git -C "$repo_root" config user.name "$prev_name"
        else
            git -C "$repo_root" config --unset user.name 2>/dev/null || true
        fi
        if [[ "$prev_email_set" == "1" ]]; then
            git -C "$repo_root" config user.email "$prev_email"
        else
            git -C "$repo_root" config --unset user.email 2>/dev/null || true
        fi
        if [[ "$prev_hooks_path_set" == "1" ]]; then
            git -C "$repo_root" config core.hooksPath "$prev_hooks_path"
        else
            git -C "$repo_root" config --unset core.hooksPath 2>/dev/null || true
        fi
    fi
}
trap restore EXIT INT TERM

if [[ -n "$name" && -n "$email" ]]; then
    prev_name=$(git -C "$repo_root" config --local user.name 2>/dev/null) && prev_name_set=1 || prev_name_set=0
    prev_email=$(git -C "$repo_root" config --local user.email 2>/dev/null) && prev_email_set=1 || prev_email_set=0
    prev_hooks_path=$(git -C "$repo_root" config --local core.hooksPath 2>/dev/null) && prev_hooks_path_set=1 || prev_hooks_path_set=0
    switched=1

    if git -C "$repo_root" config user.name "$name" \
        && git -C "$repo_root" config user.email "$email" \
        && git -C "$repo_root" config core.hooksPath "$HOOKS_DIR"; then
        : # switched fine
    else
        echo "commit.sh: failed to set persona identity, falling back to your regular git identity" >&2
        switched=0
    fi
else
    echo "commit.sh: no valid persona configured in $SKILL_MD, committing under your regular git identity" >&2
fi

git -C "$repo_root" commit "$@"
exit_code=$?
exit "$exit_code"
