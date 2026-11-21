#!/bin/sh
set -u
LABEL="io.github.livewall"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Library/Application Support/livewall"
echo "livewall removed."
