#!/usr/bin/env bash
# Switches the active `gh` account to the configured persona's GitHub
# account, so `git push` / `gh pr create` authenticate as it instead of you.
#
# This is global to the `gh` CLI (one active account at a time) — it affects
# pushes from every repo, not just the one you run this in, until you run
# push-account-uninstall.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"
STATE_FILE="${SCRIPT_DIR}/../.push-account-state.json"

command -v gh &>/dev/null || { echo "gh CLI not found — install it first: https://cli.github.com" >&2; exit 1; }

extract_field() {
    awk -v f="$1" '
        /<!-- mauw-identity/ { inblock=1; next }
        inblock && /-->/ { inblock=0 }
        inblock && $0 ~ "^"f":" {
            sub("^"f":[ \t]*", "");
            print;
            exit
        }
    ' "$SKILL_MD"
}

gh_user="$(extract_field github_username)"

case "$gh_user" in
    *REPLACE_ME*|"")
        echo "SKILL.md's identity block still has a placeholder github_username — edit ${SKILL_MD} first." >&2
        exit 1
        ;;
esac

if [[ -f "$STATE_FILE" ]]; then
    echo "Already installed (found $STATE_FILE). Run push-account-uninstall.sh first if you want to reinstall." >&2
    exit 1
fi

gh auth status --hostname github.com 2>&1 | grep -qi "account $gh_user" || {
    echo "Not logged into gh as $gh_user yet." >&2
    echo "Run: gh auth login --hostname github.com" >&2
    echo "gh will detect you're already logged in and offer to add another account — sign in as $gh_user." >&2
    exit 1
}

prev_gh_user="$(gh auth status 2>&1 | awk '
    { for (i=1;i<=NF;i++) if ($i=="account") cur=$(i+1) }
    /Active account: true/ { print cur; exit }
')"

if [[ -n "$prev_gh_user" ]]; then
    printf '{"prev_gh_user": "%s"}\n' "$prev_gh_user" > "$STATE_FILE"
else
    printf '{"prev_gh_user": null}\n' > "$STATE_FILE"
fi

gh auth setup-git >/dev/null
gh auth switch --hostname github.com --user "$gh_user" >/dev/null

echo "gh's active account is now $gh_user — this is global to gh, so pushes in OTHER repos"
echo "use these credentials too until you run push-account-uninstall.sh."
