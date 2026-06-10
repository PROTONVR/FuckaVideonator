#!/usr/bin/env sh
set -eu

SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE="$SOURCE_DIR/vestroyer"
TARGET="/usr/local/bin/vestroyer"

if [ -t 1 ]; then
  GREEN=$(printf '\033[32m')
  RED=$(printf '\033[31m')
  YELLOW=$(printf '\033[33m')
  RESET=$(printf '\033[0m')
else
  GREEN=""
  RED=""
  YELLOW=""
  RESET=""
fi

log() {
  printf '%s\n' "$*"
}

dep_status() {
  name=$1
  state=$2
  detail=$3
  case "$state" in
    ok) color=$GREEN; label="installed" ;;
    missing) color=$RED; label="missing" ;;
    *) color=$YELLOW; label="$state" ;;
  esac
  printf '%s[%s]%s %s - %s%s\n' "$color" "$label" "$RESET" "$name" "$detail" "$RESET"
}

detect_pkg_mgr() {
  if command -v apt-get >/dev/null 2>&1; then
    echo apt
  elif command -v dnf >/dev/null 2>&1; then
    echo dnf
  elif command -v yum >/dev/null 2>&1; then
    echo yum
  elif command -v pacman >/dev/null 2>&1; then
    echo pacman
  elif command -v apk >/dev/null 2>&1; then
    echo apk
  elif command -v zypper >/dev/null 2>&1; then
    echo zypper
  else
    echo unknown
  fi
}

pkg_name_for_dep() {
  dep=$1
  case "$dep" in
    python3) printf '%s\n' "python3" ;;
    ffmpeg) printf '%s\n' "ffmpeg" ;;
    *) printf '%s\n' "$dep" ;;
  esac
}

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    return 1
  fi
}

install_pkg() {
  dep=$1
  pkg_mgr=$2
  pkg=$(pkg_name_for_dep "$dep")

  log "${YELLOW}installing dependency:${RESET} $dep"

  case "$pkg_mgr" in
    apt)
      run_privileged apt-get update
      run_privileged apt-get install -y "$pkg"
      ;;
    dnf)
      run_privileged dnf install -y "$pkg"
      ;;
    yum)
      run_privileged yum install -y "$pkg"
      ;;
    pacman)
      run_privileged pacman -Sy --noconfirm "$pkg"
      ;;
    apk)
      run_privileged apk add --no-cache "$pkg"
      ;;
    zypper)
      run_privileged zypper --non-interactive install "$pkg"
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_dep() {
  name=$1
  pkg_mgr=$2

  if command -v "$name" >/dev/null 2>&1; then
    dep_status "$name" ok "$(command -v "$name")"
    return 0
  fi

  dep_status "$name" missing "will install now"
  return 1
}

prompt_install() {
  reply=""
  printf 'Do you want to install vestroyer with dependencies (python3, ffmpeg)? [y/n] '
  if [ -t 0 ]; then
    IFS= read -r reply
  elif IFS= read -r reply; then
    :
  elif [ -r /dev/tty ]; then
    IFS= read -r reply </dev/tty
  fi

  case "$reply" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

main() {
  if [ ! -f "$SOURCE" ]; then
    log "error: vestroyer script not found next to install.sh"
    exit 1
  fi

  pkg_mgr=$(detect_pkg_mgr)
  log "Vestroyer Linux CLI installer"
  log "Dependencies: python3, ffmpeg"

  if [ "$pkg_mgr" = unknown ]; then
    log "error: no supported package manager found"
    log "install python3 and ffmpeg manually, then run install.sh again"
    exit 1
  fi

  log "package manager: $pkg_mgr"

  log "checking dependencies..."
  missing_deps=""
  if ! ensure_dep python3 "$pkg_mgr"; then
    missing_deps="$missing_deps python3"
  fi
  if ! ensure_dep ffmpeg "$pkg_mgr"; then
    missing_deps="$missing_deps ffmpeg"
  fi

  if ! prompt_install; then
    log "installation cancelled"
    exit 0
  fi

  if [ -n "$missing_deps" ]; then
    for dep in $missing_deps; do
      install_pkg "$dep" "$pkg_mgr"
    done
  else
    log "${GREEN}all dependencies already installed${RESET}"
  fi

  log "copying vestroyer to $TARGET"
  chmod +x "$SOURCE"
  if [ "$(id -u)" -eq 0 ]; then
    cp "$SOURCE" "$TARGET"
    chmod 755 "$TARGET"
  elif command -v sudo >/dev/null 2>&1; then
    sudo cp "$SOURCE" "$TARGET"
    sudo chmod 755 "$TARGET"
  else
    log "error: root privileges required to install to $TARGET"
    exit 1
  fi

  log "installed: $TARGET"
  log "run: vestroyer --help"
}

main "$@"
