#!/usr/bin/env bash
# Install git-meow skill globally for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills/git-meow"
COMMANDS_DIR="${HOME}/.claude/commands"

if [[ -f "${SKILLS_DIR}/SKILL.md" ]]; then
  echo "Already installed — updating scripts/hooks, keeping your persona."
else
  echo "Installing git-meow..."
fi

mkdir -p "${SKILLS_DIR}/scripts" "${SKILLS_DIR}/githooks" "${COMMANDS_DIR}"

if [[ -f "${SKILLS_DIR}/SKILL.md" ]]; then
  : # keep existing persona/identity customization
else
  cp "${SCRIPT_DIR}/skills/git-meow/SKILL.md" "${SKILLS_DIR}/SKILL.md"
  echo "  Skill:   ${SKILLS_DIR}/SKILL.md"
fi

cp "${SCRIPT_DIR}/skills/git-meow/scripts/commit.sh" "${SKILLS_DIR}/scripts/commit.sh"
cp "${SCRIPT_DIR}/skills/git-meow/scripts/push-account-install.sh" "${SKILLS_DIR}/scripts/push-account-install.sh"
cp "${SCRIPT_DIR}/skills/git-meow/scripts/push-account-uninstall.sh" "${SKILLS_DIR}/scripts/push-account-uninstall.sh"
cp "${SCRIPT_DIR}/skills/git-meow/scripts/setup-persona.sh" "${SKILLS_DIR}/scripts/setup-persona.sh"
cp "${SCRIPT_DIR}/skills/git-meow/scripts/grant-repo-access.sh" "${SKILLS_DIR}/scripts/grant-repo-access.sh"
chmod +x "${SKILLS_DIR}/scripts/"*.sh

cp "${SCRIPT_DIR}/skills/git-meow/githooks/commit-msg" "${SKILLS_DIR}/githooks/commit-msg"
cp "${SCRIPT_DIR}/skills/git-meow/githooks/pre-commit" "${SKILLS_DIR}/githooks/pre-commit"
chmod +x "${SKILLS_DIR}/githooks/commit-msg" "${SKILLS_DIR}/githooks/pre-commit"

cp "${SCRIPT_DIR}/commands/git-meow.md" "${COMMANDS_DIR}/git-meow.md"

echo "  Scripts/hooks/command in place."

# core.hooksPath set globally so plain `git commit` (by an AI agent) is
# rejected everywhere until routed through commit.sh. Also disables any
# repo-local hooks (husky, pre-commit, lefthook) while installed — see README.
STATE_FILE="${SKILLS_DIR}/.prev-global-hookspath"
prev_hooks_path="$(git config --global core.hooksPath 2>/dev/null || true)"

if [[ "$prev_hooks_path" == "$SKILLS_DIR/githooks" ]]; then
  : # already installed, nothing to save
elif [[ -n "$prev_hooks_path" ]]; then
  echo "$prev_hooks_path" > "$STATE_FILE"
  echo "  Overriding existing global core.hooksPath ($prev_hooks_path) — saved, uninstall.sh restores it."
else
  rm -f "$STATE_FILE"
fi

git config --global core.hooksPath "${SKILLS_DIR}/githooks"

echo ""
echo "Done."

# --- Persona configured check ---
# commit.sh silently falls back to your real git identity if the identity
# block still has placeholder values — so without this, install finishing
# cleanly reads as "it's ready," when git-meow actually wouldn't attribute
# anything to a persona yet.
extract_field() {
  awk -v f="$1" '
      /<!-- meow-identity/ { inblock=1; next }
      inblock && /-->/ { inblock=0 }
      inblock && $0 ~ "^"f":" {
          sub("^"f":[ \t]*", "");
          print;
          exit
      }
  ' "${SKILLS_DIR}/SKILL.md" 2>/dev/null
}
cur_name="$(extract_field name)"
cur_email="$(extract_field email)"

case "${cur_name}${cur_email}" in
  *REPLACE_ME*|"")
    echo "No persona configured yet — commits fall back silently to your own git identity until you set one."
    if [[ -t 0 ]]; then
      read -rp "Run setup-persona.sh now? [Y/n]: " run_now
      if [[ ! "$run_now" =~ ^[Nn] ]]; then
        exec "${SKILLS_DIR}/scripts/setup-persona.sh"
      fi
    fi
    echo "  ${SKILLS_DIR}/scripts/setup-persona.sh"
    ;;
  *)
    echo "Persona: ${cur_name} <${cur_email}>  (change: ${SKILLS_DIR}/scripts/setup-persona.sh)"
    ;;
esac
