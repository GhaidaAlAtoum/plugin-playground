#!/bin/bash
# Install the macOS menu bar component of claude-tracker as a LaunchAgent.
# The plugin (statusline, /cost skill, Stop hook) works without this — the
# menu bar is optional ambient display.

if [ "$EUID" -eq 0 ]; then
    echo "❌ Do NOT run as root. Run as: ./install.sh"
    exit 1
fi

WRAPPER_NAME="start.sh"
PLIST_NAME="com.user.claudetracker.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER_PATH="$CURRENT_DIR/$WRAPPER_NAME"

if [ ! -f "$WRAPPER_PATH" ]; then
    echo "❌ $WRAPPER_NAME not found at $WRAPPER_PATH"
    exit 1
fi

mkdir -p "$LAUNCH_AGENTS_DIR"

if [ -f "$PLIST_PATH" ]; then
    launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null
    if [ ! -w "$PLIST_PATH" ]; then
        echo "⚠️  Old plist is locked. Using sudo to remove it…"
        sudo rm "$PLIST_PATH"
    else
        rm "$PLIST_PATH"
    fi
fi

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.claudetracker</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$WRAPPER_PATH</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$CURRENT_DIR</string>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "------------------------------------------------"
echo "✅ Menu bar app installed. Pointing at:"
echo "   📂 $CURRENT_DIR"
echo "------------------------------------------------"
