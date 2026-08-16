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

echo "== git-meow persona setup =="
echo "This decides who gets credit for commits Claude makes on your behalf (and, optionally,"
echo "who pushes/opens PRs) — everywhere on this machine, no per-repo setup."
echo

cur_name="$(extract_field name)"
cur_email="$(extract_field email)"
cur_user="$(extract_field github_username)"

if ! is_placeholder "$cur_name" && ! is_placeholder "$cur_email"; then
    echo "Currently configured: $cur_name <$cur_email>${cur_user:+ (github: $cur_user)}"
    read -rp "Reconfigure it? [y/N]: " reconfig
    if [[ ! "$reconfig" =~ ^[Yy] ]]; then
        echo "Keeping existing persona. Nothing changed."
        exit 0
    fi
    echo
fi

has_gh=0
command -v gh &>/dev/null && has_gh=1

use_gh="n"
if [[ "$has_gh" == 1 ]]; then
    read -rp "Does this persona have its own GitHub account you want it to push/open PRs as? [y/N]: " use_gh
else
    echo "gh CLI not found (https://cli.github.com) — persona will be commit-author-only, no GitHub account path."
fi

name=""
email=""
gh_user=""

if [[ "$use_gh" =~ ^[Yy] ]]; then
    read -rp "Persona's GitHub username: " gh_user
    [[ -n "$gh_user" ]] || { echo "No username given — aborting." >&2; exit 1; }

    auth_status="$(gh auth status --hostname github.com 2>&1)"
    if grep -qi "account $gh_user" <<<"$auth_status"; then
        echo "Already logged into gh as $gh_user — skipping login."
    else
        echo
        echo "Not logged into gh as $gh_user yet. About to start a browser login —"
        echo "sign in using ${gh_user}'s OWN GitHub credentials, not yours."
        read -rp "Press enter to continue..." _
        gh auth login --hostname github.com --git-protocol https --web
    fi

    echo "Verifying the login is actually $gh_user (not a typo or the wrong account)..."
    persona_token="$(gh auth token --hostname github.com --user "$gh_user" 2>/dev/null || true)"
    actual_login="$(GH_TOKEN="$persona_token" gh api user --jq .login 2>/dev/null || true)"
    if [[ -z "$persona_token" || "$actual_login" != "$gh_user" ]]; then
        echo "Error: gh has no account logged in matching '$gh_user' (found: '${actual_login:-none}')." >&2
        echo "Check the username and re-run this script." >&2
        exit 1
    fi
    echo "Confirmed: logged in as $gh_user."

    echo "Fetching $gh_user's profile to suggest a name and email..."
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

echo
echo "Identity written to $SKILL_MD:"
echo "  name:            $(extract_field name)"
echo "  email:           $(extract_field email)"
echo "  github_username: $(extract_field github_username)"
echo "(Commits are already attributed to this identity from here on — nothing more needed for that part.)"

if [[ ! "$use_gh" =~ ^[Yy] ]]; then
    echo
    echo "Done. Pushes/PRs stay under your own gh account; only commit authorship uses $name."
    exit 0
fi

echo
echo "Now switching gh's active account to $gh_user so pushes/PRs authenticate as it."
echo "This is GLOBAL to the gh CLI — it affects pushes from EVERY repo on this machine,"
echo "including your own manual git/gh commands, until you run push-account-uninstall.sh."
read -rp "Continue? [y/N]: " do_switch
if [[ ! "$do_switch" =~ ^[Yy] ]]; then
    echo "Skipped. Identity is set, but pushes/PRs still authenticate as you."
    echo "Run ${SCRIPT_DIR}/push-account-install.sh later if you change your mind."
    exit 0
fi

prev_active="$(awk '{for(i=1;i<=NF;i++) if($i=="account") cur=$(i+1)} /Active account: true/ {print cur; exit}' <<<"$auth_status")"
echo "(Your own gh account, $prev_active, is saved — push-account-uninstall.sh restores it.)"

rm -f "${SCRIPT_DIR}/../.push-account-state.json"  # allow re-running this setup
"${SCRIPT_DIR}/push-account-install.sh"

echo
echo "gh's active account is now $gh_user."
echo
echo "One more thing: $gh_user still needs actual PUSH ACCESS on each repo before it can push —"
echo "being the active gh account doesn't grant permissions by itself. Run this whenever you hit"
echo "a repo it can't push to (one repo, or scan a directory for all of them):"
echo "  ${SCRIPT_DIR}/grant-repo-access.sh"
