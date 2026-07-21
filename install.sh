#!/usr/bin/env bash
# install.sh — Install all plugins or a specific one
#
# One-line install (clones a temp copy, installs, cleans up):
#   curl -fsSL https://raw.githubusercontent.com/jayf0x/claude-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/jayf0x/claude-skills/main/install.sh | bash -s -- kronny
#
# Local clone:
#   ./install.sh                    — install all plugins
#   ./install.sh safe-pause  — install one plugin
#   ./install.sh uninstall <name>   — uninstall a plugin
set -euo pipefail

REPO_URL="https://github.com/jayf0x/claude-skills.git"

# BASH_SOURCE is unset when bash is invoked from stdin (curl | bash); default
# to empty so `set -u` doesn't trip, and so we fall through to the clone path.
here="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || here=""
if [[ -z "$here" || ! -d "$here/plugins" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "install.sh: git required." >&2
    exit 1
  fi
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --depth 1 -q "$REPO_URL" "$tmp/claude-skills"
  exec bash "$tmp/claude-skills/install.sh" "$@"
fi

SCRIPT_DIR="$here"
ACTION="install"
PLUGIN=""

usage() {
  cat <<'EOF'
Usage:
  ./install.sh                         install all plugins
  ./install.sh <plugin>                install one plugin
  ./install.sh uninstall               uninstall all plugins
  ./install.sh uninstall <plugin>      uninstall one plugin

Plugins: safe-pause, plan-next
EOF
}

list_plugins() {
  for dir in "${SCRIPT_DIR}"/plugins/*/; do
    [[ -f "${dir}install.sh" ]] || continue
    basename "$dir"
  done
}

run_plugin() {
  local name="$1"
  local script="${SCRIPT_DIR}/plugins/${name}/${ACTION}.sh"

  if [[ ! -f "$script" ]]; then
    echo "Error: plugin '${name}' not found or missing ${ACTION}.sh" >&2
    exit 1
  fi

  bash "$script"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    uninstall)
      ACTION="uninstall"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown flag '$1'" >&2
      usage
      exit 1
      ;;
    *)
      PLUGIN="$1"
      shift
      ;;
  esac
done

if [[ -n "$PLUGIN" ]]; then
  run_plugin "$PLUGIN"
else
  while IFS= read -r name; do
    run_plugin "$name"
    echo ""
  done < <(list_plugins)
fi
