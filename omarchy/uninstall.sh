#!/bin/sh
set -u
AUTOSTART="$HOME/.config/hypr/autostart.lua"
pkill -x livewall 2>/dev/null
[ -f "$AUTOSTART" ] && sed -i '/^-- livewall:/d; /launch_on_start("livewall")/d' "$AUTOSTART"
rm -f "$HOME/.local/bin/livewall"
rm -rf "$HOME/.local/share/livewall"
echo "livewall removed."
