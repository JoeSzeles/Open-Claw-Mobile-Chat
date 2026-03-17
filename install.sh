#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="$SCRIPT_DIR/files"
BACKUP_DIR=".mobile-chat-backup"
VERSION="2026.3.17"

echo "╔════════════════════════════════════════════════════════╗"
echo "║  OpenClaw Mobile Chat Installer v$VERSION             ║"
echo "║  Hands-Free · Bluetooth · Phone Capabilities          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

detect_openclaw() {
  if [ -n "${1:-}" ] && [ -d "$1" ]; then
    echo "$1"
    return
  fi
  local home="${HOME:-$(eval echo ~)}"
  for candidate in "$home/openclaw" "./openclaw" "."; do
    if [ -d "$candidate" ] && [ -f "$candidate/package.json" ] && [ -d "$candidate/dist" ]; then
      local resolved
      resolved="$(cd "$candidate" && pwd)"
      echo "$resolved"
      return
    fi
  done
  echo ""
}

OPENCLAW_ROOT=$(detect_openclaw "${1:-}")

if [ -z "$OPENCLAW_ROOT" ]; then
  echo "ERROR: Could not find OpenClaw installation."
  echo "Usage: bash install.sh /path/to/openclaw"
  echo ""
  echo "Provide the root directory of your OpenClaw installation."
  exit 1
fi

if [ ! -d "$FILES_DIR" ]; then
  echo "ERROR: files/ directory not found next to this script."
  echo "Make sure you cloned the full repository."
  exit 1
fi

echo "OpenClaw root: $OPENCLAW_ROOT"
echo ""

BACKUP_PATH="$OPENCLAW_ROOT/$BACKUP_DIR"
INSTALLED_LIST="$BACKUP_PATH/installed-files.txt"
BACKED_UP_LIST="$BACKUP_PATH/backed-up-files.txt"

mkdir -p "$BACKUP_PATH"

backed_up=0
installed=0
new_files=0

echo "[1/2] Backing up files that will be overwritten..."

cd "$FILES_DIR"
find . -type f | sed 's|^\./||' | sort | while IFS= read -r rel; do
  target="$OPENCLAW_ROOT/$rel"
  if [ -f "$target" ]; then
    backup_target="$BACKUP_PATH/$rel"
    mkdir -p "$(dirname "$backup_target")"
    cp "$target" "$backup_target"
    echo "$rel" >> "$BACKED_UP_LIST.tmp"
  fi
done

if [ -f "$BACKED_UP_LIST.tmp" ]; then
  sort "$BACKED_UP_LIST.tmp" > "$BACKED_UP_LIST"
  rm -f "$BACKED_UP_LIST.tmp"
  backed_up=$(wc -l < "$BACKED_UP_LIST")
else
  touch "$BACKED_UP_LIST"
fi

echo "  Backed up $backed_up existing files to $BACKUP_DIR/"
echo ""

echo "[2/2] Installing Mobile Chat files..."

cd "$FILES_DIR"
find . -type f | sed 's|^\./||' | sort | while IFS= read -r rel; do
  target="$OPENCLAW_ROOT/$rel"
  mkdir -p "$(dirname "$target")"
  cp "$FILES_DIR/$rel" "$target"
  echo "$rel" >> "$INSTALLED_LIST.tmp"
done

if [ -f "$INSTALLED_LIST.tmp" ]; then
  sort "$INSTALLED_LIST.tmp" > "$INSTALLED_LIST"
  rm -f "$INSTALLED_LIST.tmp"
  installed=$(wc -l < "$INSTALLED_LIST")
  new_files=$((installed - backed_up))
fi

echo "  Installed $installed files ($new_files new, $backed_up updated)"
echo ""

echo "════════════════════════════════════════════════════════"
echo "  INSTALL COMPLETE"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  Files installed: $installed"
echo "  Backed up:       $backed_up"
echo "  New files:       $new_files"
echo ""
echo "  Access Mobile Chat at:"
echo "    https://your-openclaw-domain/mobile-chat.html"
echo ""
echo "  Quick Start:"
echo "    1. Pair phone to car via Bluetooth"
echo "    2. Open Mobile Chat page in Chrome on your phone"
echo "    3. Tap Drive or press Play on car radio"
echo "    4. Speak naturally — 2 second pause sends your message"
echo ""
