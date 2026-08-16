#!/usr/bin/env bash
# Interactive one-shot setup for a git-meow persona. Configures:
#   1. The identity block in SKILL.md (who gets credit for commits)
#   2. Optionally, a real GitHub account for the persona to push/PR as
# Safe to re-run — on a new machine, to swap personas, or to redo either step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"

if [[ ! -f "$SKILL_MD" || ! -x "${SCRIPT_DIR}/commit.sh" || ! -f "${SCRIPT_DIR}/../githooks/pre-commit" ]]; then
    echo "git-meow isn't fully installed — run install.sh first." >&2
    exit 1
fi

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

# Identity is the only required part: name/email is what shows up as the
# commit author. Nothing here needs GitHub — pushes still go out under your
# own gh account either way, this is just the name on the commit.
read -rp "Persona name: " name
read -rp "Persona email: " email

[[ -n "$name" ]] || { echo "Name can't be empty — aborting." >&2; exit 1; }
[[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || { echo "'$email' doesn't look like a valid email — aborting." >&2; exit 1; }

awk -v name="$name" -v email="$email" '
  /<!-- meow-identity/ { inblock=1 }
  inblock && /^name:/ { print "name: " name; next }
  inblock && /^email:/ { print "email: " email; next }
  inblock && /-->/ { inblock=0 }
  { print }
' "$SKILL_MD" > "${SKILL_MD}.tmp" && mv "${SKILL_MD}.tmp" "$SKILL_MD"

echo "Identity set: $name <$email> — commits will be authored as this from now on."

command -v gh &>/dev/null || exit 0

# --- Optional: push/PR as the persona's own GitHub account -----------------
# What this does and doesn't do:
#   - The identity above is ALREADY enough to get commit-author credit — this
#     step is unrelated to that, and skipping it changes nothing about it.
#   - This is only about who *pushes* / *opens PRs*: by default that's still
#     you (your own gh login), even though commits are authored as the
#     persona. Say yes here only if you want the persona to have its own
#     real GitHub account doing the pushing/PR-opening too.
#   - Saying yes logs into gh CLI as a second account and can switch gh's
#     *active* account globally (every repo on this machine, until you
#     revert it) — that's a bigger footprint than just the commit identity.
echo
read -rp "Also give '$name' its own GitHub account for pushes/PRs (optional, separate from the above)? [y/N]: " use_gh
[[ "$use_gh" =~ ^[Yy] ]] || exit 0

before="$(gh_accounts)"
echo "Sign in as that account (browser login)."
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

awk -v user="$gh_user" '
  /<!-- meow-identity/ { inblock=1 }
  inblock && /^github_username:/ { print "github_username: " user; next }
  inblock && /-->/ { inblock=0 }
  { print }
' "$SKILL_MD" > "${SKILL_MD}.tmp" && mv "${SKILL_MD}.tmp" "$SKILL_MD"

echo "Persona's GitHub account: $gh_user"
echo
read -rp "Switch gh's active account to $gh_user now (global, affects every repo on this machine)? [y/N]: " do_switch
if [[ ! "$do_switch" =~ ^[Yy] ]]; then
    echo "Skipped. Run ${SCRIPT_DIR}/push-account-install.sh later if you change your mind."
    exit 0
fi

rm -f "${SCRIPT_DIR}/../.push-account-state.json"  # allow re-running this setup
"${SCRIPT_DIR}/push-account-install.sh"

echo "Note: $gh_user also needs push access on each repo — run ${SCRIPT_DIR}/grant-repo-access.sh when it can't push."
