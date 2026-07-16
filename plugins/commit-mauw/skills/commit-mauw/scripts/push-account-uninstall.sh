#!/usr/bin/env bash
# Reverts push-account-install.sh: switches gh's active account back to
# whatever it was before, using the snapshot taken at install time.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="${SCRIPT_DIR}/../.push-account-state.json"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "No install state found ($STATE_FILE) — nothing to revert." >&2
    exit 1
fi

prev_gh_user="$(awk -F'"' '/prev_gh_user/{print $4}' "$STATE_FILE")"

if [[ -n "$prev_gh_user" ]]; then
    gh auth switch --hostname github.com --user "$prev_gh_user" >/dev/null 2>&1 || \
        echo "Warning: couldn't switch gh back to $prev_gh_user automatically — run 'gh auth switch --user $prev_gh_user' yourself." >&2
else
    echo "No previous gh account was recorded — leaving gh's active account as-is." >&2
fi

rm -f "$STATE_FILE"
echo "Reverted. gh's active account restored to what it was before install."
