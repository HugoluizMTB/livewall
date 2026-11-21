#!/bin/sh
# Build livewall, set a page as the wallpaper and start it at login.
# Usage: ./install.sh [page.html]   (default: examples/black-hole.html)
set -eu
cd "$(dirname "$0")"
PAGE="${1:-examples/black-hole.html}"
DIR="$HOME/Library/Application Support/livewall"
LABEL="io.github.livewall"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

mkdir -p "$DIR" "$HOME/Library/LaunchAgents"
swiftc -O main.swift -o "$DIR/livewall"
cp "$PAGE" "$DIR/wallpaper.html"

cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$DIR/livewall</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ProcessType</key><string>Interactive</string>
</dict></plist>
PL

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "livewall is running. Change the page: ./install.sh other.html"
