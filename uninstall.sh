#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codex-window-keeper"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/codex-window-keeper"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
LAUNCHD_LABEL="com.matpb.codex-window-keeper"

# uname -s is the real detection; OSTYPE (a bash builtin, no external binary
# needed) is the fallback for a PATH stripped down to bare essentials.
if command -v uname >/dev/null 2>&1; then
  OS="$(uname -s)"
else
  case "${OSTYPE:-}" in
    darwin*) OS="Darwin" ;;
    *) OS="Linux" ;;
  esac
fi

purge=0
for arg in "$@"; do
  case "$arg" in
    --purge) purge=1 ;;
    *) echo "unknown argument: $arg" >&2; exit 1 ;;
  esac
done

if [[ "$OS" == "Darwin" ]]; then
  launchctl bootout "gui/$(id -u)/$LAUNCHD_LABEL" 2>/dev/null || true
  rm -f "$LAUNCHD_DIR/$LAUNCHD_LABEL.plist"
  rm -f "$BIN_DIR/codex-window-keeper"
  echo "removed $BIN_DIR/codex-window-keeper and the launchd agent"
else
  systemctl --user disable --now codex-window-keeper.timer 2>/dev/null || true
  rm -f "$SYSTEMD_USER_DIR/codex-window-keeper.service" "$SYSTEMD_USER_DIR/codex-window-keeper.timer"
  systemctl --user daemon-reload 2>/dev/null || true
  rm -f "$BIN_DIR/codex-window-keeper"
  echo "removed $BIN_DIR/codex-window-keeper and systemd units"
fi

if [[ "$purge" -eq 1 ]]; then
  rm -rf "$CONFIG_DIR" "$STATE_DIR"
  echo "purged config and state directories"
else
  echo "config and state left in place, rerun with --purge to remove them"
fi

echo "uninstalled codex-window-keeper"
