#!/usr/bin/env bash
# install.sh — Install all plugins or a specific one
#
# Usage:
#   ./install.sh                    — install all plugins
#   ./install.sh pause-claude-code  — install one plugin
#   ./install.sh uninstall <name>   — uninstall a plugin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACTION="install"
PLUGIN=""

usage() {
  cat <<'EOF'
Usage:
  ./install.sh                         install all plugins
  ./install.sh <plugin>                install one plugin
  ./install.sh uninstall               uninstall all plugins
  ./install.sh uninstall <plugin>      uninstall one plugin

Plugins: pause-claude-code, plan-next
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
