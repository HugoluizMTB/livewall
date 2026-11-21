#!/bin/sh
# Build livewall, set a page as the wallpaper and start it with Hyprland.
# Usage: ./install.sh [page.html]   (default: ../examples/black-hole.html)
set -eu
PAGE="$(realpath "${1:-$(dirname "$0")/../examples/black-hole.html}")"
cd "$(dirname "$0")"
BIN="$HOME/.local/bin/livewall"
DIR="$HOME/.local/share/livewall"
AUTOSTART="$HOME/.config/hypr/autostart.lua"

mkdir -p build "$DIR" "$(dirname "$BIN")"
(cd build && qmake6 ../livewall.pro >/dev/null && make -s -j"$(nproc)")
install -m755 build/livewall "$BIN"
cp "$PAGE" "$DIR/wallpaper.html"

if [ -f "$AUTOSTART" ] && ! grep -q 'launch_on_start("livewall")' "$AUTOSTART"; then
  printf '\n-- livewall: HTML page as a live wallpaper\no.launch_on_start("livewall")\n' >> "$AUTOSTART"
fi

pkill -x livewall 2>/dev/null || true
setsid "$BIN" >/dev/null 2>&1 &
echo "livewall is running. Change the page: ./install.sh other.html"
