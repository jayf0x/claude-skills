#!/usr/bin/env bash
# Install git-meow skill globally for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills/git-meow"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "Installing git-meow..."

mkdir -p "${SKILLS_DIR}/scripts" "${SKILLS_DIR}/githooks" "${COMMANDS_DIR}"

if [[ -f "${SKILLS_DIR}/SKILL.md" ]]; then
  echo "  SKILL.md already exists at ${SKILLS_DIR}/SKILL.md — leaving your identity/voice customization alone."
  echo "  (edit it directly, or delete it and re-run install.sh, to reset to the template)"
else
  cp "${SCRIPT_DIR}/skills/git-meow/SKILL.md" "${SKILLS_DIR}/SKILL.md"
  echo "  Skill:   ${SKILLS_DIR}/SKILL.md (edit the identity block inside to set your own persona)"
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

echo "  Scripts: ${SKILLS_DIR}/scripts/"
echo "  Hooks:   ${SKILLS_DIR}/githooks/"
echo "  Command: ${COMMANDS_DIR}/git-meow.md"

# --- Global enforcement gate ---
# core.hooksPath is a single value per git-config scope — setting it globally
# means it replaces .git/hooks (and any repo-local hooksPath override such as
# husky, pre-commit framework, or lefthook) in EVERY repo on this machine,
# until uninstall.sh reverts it. This is what actually blocks plain
# `git commit` — the skill instructions alone can't (an LLM can forget/skip
# them), a hook that git itself enforces can't be forgotten.
STATE_FILE="${SKILLS_DIR}/.prev-global-hookspath"
prev_hooks_path="$(git config --global core.hooksPath 2>/dev/null || true)"

if [[ "$prev_hooks_path" == "$SKILLS_DIR/githooks" ]]; then
  : # already installed, nothing to save
elif [[ -n "$prev_hooks_path" ]]; then
  echo "$prev_hooks_path" > "$STATE_FILE"
  echo "  Note: overriding your existing global core.hooksPath ($prev_hooks_path)."
  echo "        Saved to $STATE_FILE — uninstall.sh restores it."
else
  rm -f "$STATE_FILE"
fi

git config --global core.hooksPath "${SKILLS_DIR}/githooks"
echo "  Gate:    core.hooksPath set globally to ${SKILLS_DIR}/githooks"
echo "           Plain 'git commit' now fails everywhere until routed through commit.sh."
echo "           WARNING: this also disables any repo-local git hooks (husky, pre-commit"
echo "           framework, lefthook, ...) machine-wide while installed — see README.md."

echo ""
echo "Done. Works in any repo — no per-repo setup needed."
echo "Restart Claude Code if it was already running."
echo ""
echo "Next: run ${SKILLS_DIR}/scripts/setup-persona.sh to set the persona's identity"
echo "(and, optionally, make it push/PR under its own GitHub account)."
