#!/usr/bin/env bash
# Interactive one-shot setup for a git-meow persona: writes the identity block
# in SKILL.md, optionally logs the persona into `gh` and switches pushes/PRs
# to authenticate as it, and optionally invites it as a push collaborator on
# your local repos (accepting the invites as the persona too). Safe to re-run
# on a new machine or with a new persona account — each step just overwrites
# state derived from the identity block below.
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

cur_name="$(extract_field name)"
cur_email="$(extract_field email)"
cur_user="$(extract_field github_username)"

read -rp "Persona name [${cur_name}]: " name; name="${name:-$cur_name}"
read -rp "Persona email [${cur_email}]: " email; email="${email:-$cur_email}"
read -rp "Persona GitHub username [${cur_user}]: " gh_user; gh_user="${gh_user:-$cur_user}"

awk -v name="$name" -v email="$email" -v user="$gh_user" '
  /<!-- meow-identity/ { inblock=1 }
  inblock && /^name:/ { print "name: " name; next }
  inblock && /^email:/ { print "email: " email; next }
  inblock && /^github_username:/ { print "github_username: " user; next }
  inblock && /-->/ { inblock=0 }
  { print }
' "$SKILL_MD" > "${SKILL_MD}.tmp" && mv "${SKILL_MD}.tmp" "$SKILL_MD"

echo "Identity set: $name <$email> ($gh_user)"
echo "(Commits are already attributed to this identity from here on — no further steps needed for that part.)"

command -v gh &>/dev/null || { echo "gh CLI not found — skipping push-as-persona setup. Install it to continue: https://cli.github.com"; exit 0; }

read -rp "Also push/PR as $gh_user (not just author commits as it)? [y/N]: " do_push
if [[ ! "$do_push" =~ ^[Yy] ]]; then
  echo "Skipped. Pushes/PRs stay under your own gh account; only commit authorship uses $name."
  exit 0
fi

auth_status="$(gh auth status --hostname github.com 2>&1)"
prev_active="$(awk '{for(i=1;i<=NF;i++) if($i=="account") cur=$(i+1)} /Active account: true/ {print cur; exit}' <<<"$auth_status")"

if ! grep -qi "account $gh_user" <<<"$auth_status"; then
  echo "Not logged into gh as $gh_user yet — logging in now (sign in as $gh_user, not yourself):"
  gh auth login --hostname github.com --git-protocol https --web
  # gh auth login activates the new account as a side effect — switch back so
  # push-account-install.sh below snapshots the correct "previous" account.
  [[ -n "$prev_active" ]] && gh auth switch --hostname github.com --user "$prev_active" >/dev/null
fi

rm -f "${SCRIPT_DIR}/../.push-account-state.json"  # allow re-running this setup
"${SCRIPT_DIR}/push-account-install.sh"

echo ""
echo "gh's active account is now $gh_user — this is global, affecting pushes in EVERY repo"
echo "(including your own manual ones) until you run push-account-uninstall.sh."
echo ""
echo "Note: $gh_user still needs push access on any repo before it can actually push there."
echo "Run scripts/grant-repo-access.sh (this repo, or all of them) whenever you hit that."
