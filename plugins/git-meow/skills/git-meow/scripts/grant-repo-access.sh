#!/usr/bin/env bash
# Invites the configured persona as a push collaborator on your repo(s), then
# accepts the invite(s) as the persona — needed before it can actually push
# anywhere, even once push.sh is authenticating as it.
# Run standalone, whenever you hit a repo the persona can't push to yet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"

command -v gh &>/dev/null || { echo "gh CLI not found: https://cli.github.com" >&2; exit 1; }

extract_field() {
    awk -v f="$1" '
        /<!-- meow-identity/ { inblock=1; next }
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
        echo "SKILL.md's identity block has no github_username set — run setup-persona.sh first." >&2
        exit 1
        ;;
esac

auth_status="$(gh auth status --hostname github.com 2>&1)"
grep -qi "account $gh_user" <<<"$auth_status" || {
    echo "Not logged into gh as $gh_user — run setup-persona.sh first." >&2
    exit 1
}

# Every OTHER logged-in gh account is a candidate repo owner to invite FROM.
# Repos can belong to different accounts (e.g. personal vs. a second login),
# so match per-repo by actual GitHub login rather than assuming a single one.
other_accounts=()
while IFS= read -r acct; do
    other_accounts+=("$acct")
done < <(awk -v skip="$gh_user" '
    /Logged in to github.com account/ {
        for (i=1;i<=NF;i++) if ($i=="account") { u=$(i+1); if (u != skip) print u }
    }
' <<<"$auth_status")
[[ "${#other_accounts[@]}" -gt 0 ]] || { echo "No other gh account logged in to invite from." >&2; exit 1; }

# Resolve each candidate account's actual GitHub login up front (no
# associative arrays — this needs to run on macOS's stock bash 3.2 too).
# Parallel arrays: other_logins[i] is the login for other_accounts[i].
other_logins=()
for acct in "${other_accounts[@]}"; do
    other_logins+=("$(GH_TOKEN="$(gh auth token --hostname github.com --user "$acct")" gh api user --jq .login 2>/dev/null || true)")
done

token_for_owner() {
    local target="$1" i
    for ((i = 0; i < ${#other_accounts[@]}; i++)); do
        if [[ "${other_logins[$i]}" == "$target" ]]; then
            gh auth token --hostname github.com --user "${other_accounts[$i]}"
            return 0
        fi
    done
    return 1
}

invite_from_remote() {
    local remote="$1" owner repo token
    [[ "$remote" == *github.com* ]] || { echo "  (skipping non-GitHub remote: $remote)"; return; }
    owner="$(sed -E 's#.*github\.com[:/]([^/]+)/([^/.]+)(\.git)?$#\1#' <<<"$remote")"
    repo="$(sed -E 's#.*github\.com[:/]([^/]+)/([^/.]+)(\.git)?$#\2#' <<<"$remote")"
    printf '  %s/%s: ' "$owner" "$repo"
    if ! token="$(token_for_owner "$owner")"; then
        echo "skipped (no logged-in gh account owns this)"
        return
    fi
    if GH_TOKEN="$token" gh api -X PUT "repos/$owner/$repo/collaborators/$gh_user" -f permission=push --silent 2>/dev/null; then
        echo "invited"
    else
        echo "skipped (archived, or already a collaborator)"
    fi
}

echo "Grant $gh_user push access to:"
echo "  1) just this repo"
echo "  2) every local repo you own, under a directory you pick"
read -rp "Choice [1]: " choice
choice="${choice:-1}"

case "$choice" in
  1)
    remote="$(git remote get-url origin 2>/dev/null || true)"
    [[ -n "$remote" ]] || { echo "Not in a git repo with an origin remote." >&2; exit 1; }
    invite_from_remote "$remote"
    ;;
  2)
    read -rp "Directory to scan for repos [~/Documents/GitHub]: " scan_dir
    scan_dir="${scan_dir:-$HOME/Documents/GitHub}"
    scan_dir="${scan_dir/#\~/$HOME}"
    for d in "$scan_dir"/*/; do
      [[ -d "${d}.git" ]] || continue
      remote="$(git -C "$d" remote get-url origin 2>/dev/null || true)"
      [[ -n "$remote" ]] || continue
      invite_from_remote "$remote"
    done
    ;;
  *)
    echo "Unrecognized choice." >&2; exit 1 ;;
esac

echo "Accepting invitations as $gh_user ..."
persona_token="$(gh auth token --hostname github.com --user "$gh_user")"
GH_TOKEN="$persona_token" gh api user/repository_invitations --paginate --jq '.[].id' | while read -r id; do
    GH_TOKEN="$persona_token" gh api -X PATCH "user/repository_invitations/$id" --silent
done
echo "Done."
