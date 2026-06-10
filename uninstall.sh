#!/usr/bin/env sh
set -eu

TARGET="/usr/local/bin/vestroyer"

if [ "$(id -u)" -eq 0 ]; then
  rm -f "$TARGET"
elif command -v sudo >/dev/null 2>&1; then
  sudo rm -f "$TARGET"
else
  echo "error: root privileges required to remove $TARGET" >&2
  exit 1
fi

echo "removed: $TARGET"
