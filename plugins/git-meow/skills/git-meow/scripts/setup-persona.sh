#!/usr/bin/env bash
# Interactive one-shot setup for a git-meow persona. Configures:
#   1. The identity block in SKILL.md (who gets credit for commits)
#   2. Optionally, a real GitHub account for the persona to push/PR as
# Safe to re-run — on a new machine, to swap personas, or to redo either step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"

[[ -f "$SKILL_MD" ]] || { echo "SKILL.md not found next to this script — run plugins/git-meow/install.sh first." >&2; exit 1; }

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

is_placeholder() { case "$1" in *REPLACE_ME*|"") return 0 ;; *) return 1 ;; esac }

gh_accounts() {
    gh auth status --hostname github.com 2>&1 | awk '
        /Logged in to github.com account/ {
            for (i=1;i<=NF;i++) if ($i=="account") print $(i+1)
        }
    '
}

echo "== git-meow persona setup =="
echo "Who gets credit for commits (and optionally pushes/PRs) as this persona."
echo

cur_name="$(extract_field name)"
cur_email="$(extract_field email)"
cur_user="$(extract_field github_username)"

if ! is_placeholder "$cur_name" && ! is_placeholder "$cur_email"; then
    echo "Currently configured: $cur_name <$cur_email>${cur_user:+ (github: $cur_user)}"
    read -rp "Reconfigure it? [y/N]: " reconfig
    if [[ ! "$reconfig" =~ ^[Yy] ]]; then
        echo "Nothing changed."
        exit 0
    fi
    echo
fi

has_gh=0
command -v gh &>/dev/null && has_gh=1

use_gh="n"
if [[ "$has_gh" == 1 ]]; then
    read -rp "Give this persona its own GitHub account to push/open PRs as? [y/N]: " use_gh
else
    echo "gh CLI not found (https://cli.github.com) — persona will be commit-author-only."
fi

name=""
email=""
gh_user=""

if [[ "$use_gh" =~ ^[Yy] ]]; then
    before="$(gh_accounts)"

    echo "Sign in as the persona's own GitHub account (browser login)."
    read -rp "Press enter to continue..." _
    gh auth login --hostname github.com --git-protocol https --web

    after="$(gh_accounts)"
    new_accounts="$(comm -13 <(sort <<<"$before") <(sort <<<"$after"))"
    new_count="$(grep -c . <<<"$new_accounts" || true)"

    if [[ "$new_count" -eq 1 ]]; then
        gh_user="$new_accounts"
    else
        echo "Which account is the persona?"
        mapfile -t all_accounts < <(gh_accounts)
        select acct in "${all_accounts[@]}"; do
            [[ -n "$acct" ]] && gh_user="$acct" && break
        done
    fi
    echo "Persona's GitHub account: $gh_user"

    persona_token="$(gh auth token --hostname github.com --user "$gh_user" 2>/dev/null || true)"
    profile_name="$(GH_TOKEN="$persona_token" gh api user --jq '.name // .login')"

    email_list="$(GH_TOKEN="$persona_token" gh api user/emails --jq '.[] | select(.verified) | .email' 2>/dev/null || true)"
    verified_emails=()
    while IFS= read -r e; do [[ -n "$e" ]] && verified_emails+=("$e"); done <<<"$email_list"

    if [[ "${#verified_emails[@]}" -eq 0 ]]; then
        echo "Warning: no verified email visible for $gh_user (needs the 'user' gh scope, or the account has none verified)."
        echo "A commit authored with an email that isn't verified on $gh_user won't count toward its"
        echo "GitHub contribution graph, even if the account itself pushes it."
        read -rp "Persona email: " email
    elif [[ "${#verified_emails[@]}" -eq 1 ]]; then
        email="${verified_emails[0]}"
        echo "Using $gh_user's verified email: $email"
    else
        echo "$gh_user has multiple verified emails:"
        for i in "${!verified_emails[@]}"; do
            echo "  $((i + 1))) ${verified_emails[$i]}"
        done
        read -rp "Pick one [1]: " pick
        pick="${pick:-1}"
        email="${verified_emails[$((pick - 1))]:-${verified_emails[0]}}"
    fi

    read -rp "Persona name [${profile_name}]: " name
    name="${name:-$profile_name}"
else
    echo
    echo "No GitHub account for the persona — it'll get commit-author credit only (the name/email"
    echo "on each commit); pushes and PRs stay under your own gh account."
    read -rp "Persona name: " name
    read -rp "Persona email: " email
    read -rp "Persona GitHub username (optional, cosmetic without gh auth) [none]: " gh_user
fi

[[ -n "$name" ]] || { echo "Name can't be empty — aborting." >&2; exit 1; }
[[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || { echo "'$email' doesn't look like a valid email — aborting." >&2; exit 1; }

awk -v name="$name" -v email="$email" -v user="$gh_user" '
  /<!-- meow-identity/ { inblock=1 }
  inblock && /^name:/ { print "name: " name; next }
  inblock && /^email:/ { print "email: " email; next }
  inblock && /^github_username:/ { print "github_username: " user; next }
  inblock && /-->/ { inblock=0 }
  { print }
' "$SKILL_MD" > "${SKILL_MD}.tmp" && mv "${SKILL_MD}.tmp" "$SKILL_MD"

echo "Identity set: $(extract_field name) <$(extract_field email)>${gh_user:+ (github: $gh_user)}"

if [[ ! "$use_gh" =~ ^[Yy] ]]; then
    exit 0
fi

echo
read -rp "Also switch gh's active account to $gh_user (global, affects every repo) now? [y/N]: " do_switch
if [[ ! "$do_switch" =~ ^[Yy] ]]; then
    echo "Skipped. Run ${SCRIPT_DIR}/push-account-install.sh later if you change your mind."
    exit 0
fi

rm -f "${SCRIPT_DIR}/../.push-account-state.json"  # allow re-running this setup
"${SCRIPT_DIR}/push-account-install.sh"

echo "Note: $gh_user also needs push access on each repo — run ${SCRIPT_DIR}/grant-repo-access.sh when it can't push."
