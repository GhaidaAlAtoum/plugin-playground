#!/bin/bash
# Uninstall the macOS menu bar component. Plugin statusline / skill / hook stay.

PLIST_NAME="com.user.claudetracker.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

LOG_FILE="$HOME/claude_tracker_debug.log"
APP_LOG="$HOME/.claude_tracker.log"
APP_CONFIG="$HOME/.claude_tracker_config.json"

echo "------------------------------------------------"
echo "🛑 Uninstalling claude-tracker menu bar…"

if launchctl list | grep -q "com.user.claudetracker"; then
    echo "   Stopping background service…"
    launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null
else
    echo "   Service not currently running."
fi

if [ -f "$PLIST_PATH" ]; then
    echo "   Removing LaunchAgent plist…"
    rm "$PLIST_PATH"
else
    echo "   LaunchAgent plist not found (already removed?)."
fi

echo "✅ Menu bar app uninstalled. It will no longer start automatically."
echo "------------------------------------------------"

echo "Remove log files and saved preferences?"
echo "   - $LOG_FILE"
echo "   - $APP_LOG"
echo "   - $APP_CONFIG"
read -p "Delete these files? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$LOG_FILE" "$APP_LOG" "$APP_CONFIG"
    echo "🗑️  Logs and config deleted."
else
    echo "   Files kept."
fi
echo "------------------------------------------------"
