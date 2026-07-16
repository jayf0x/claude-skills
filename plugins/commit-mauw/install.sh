#!/usr/bin/env bash
# Install commit-mauw skill globally for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills/commit-mauw"
COMMANDS_DIR="${HOME}/.claude/commands"

echo "Installing commit-mauw..."

mkdir -p "${SKILLS_DIR}/scripts" "${SKILLS_DIR}/githooks" "${COMMANDS_DIR}"

if [[ -f "${SKILLS_DIR}/SKILL.md" ]]; then
  echo "  SKILL.md already exists at ${SKILLS_DIR}/SKILL.md — leaving your identity/voice customization alone."
  echo "  (edit it directly, or delete it and re-run install.sh, to reset to the template)"
else
  cp "${SCRIPT_DIR}/skills/commit-mauw/SKILL.md" "${SKILLS_DIR}/SKILL.md"
  echo "  Skill:   ${SKILLS_DIR}/SKILL.md (edit the identity block inside to set your own persona)"
fi

cp "${SCRIPT_DIR}/skills/commit-mauw/scripts/commit.sh" "${SKILLS_DIR}/scripts/commit.sh"
cp "${SCRIPT_DIR}/skills/commit-mauw/scripts/push-account-install.sh" "${SKILLS_DIR}/scripts/push-account-install.sh"
cp "${SCRIPT_DIR}/skills/commit-mauw/scripts/push-account-uninstall.sh" "${SKILLS_DIR}/scripts/push-account-uninstall.sh"
chmod +x "${SKILLS_DIR}/scripts/"*.sh

cp "${SCRIPT_DIR}/skills/commit-mauw/githooks/commit-msg" "${SKILLS_DIR}/githooks/commit-msg"
chmod +x "${SKILLS_DIR}/githooks/commit-msg"

cp "${SCRIPT_DIR}/commands/commit-mauw.md" "${COMMANDS_DIR}/commit-mauw.md"

echo "  Scripts: ${SKILLS_DIR}/scripts/"
echo "  Hook:    ${SKILLS_DIR}/githooks/commit-msg"
echo "  Command: ${COMMANDS_DIR}/commit-mauw.md"
echo ""
echo "Done. Works in any repo — no per-repo setup needed."
echo "Restart Claude Code if it was already running."
