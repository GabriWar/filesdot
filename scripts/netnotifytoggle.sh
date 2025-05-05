#!/bin/bash

# Determine if the netmon notifier.py script is running
if pgrep -f "python.*notifier.py" > /dev/null; then
    # If it's running, kill it
    pkill -f "python.*notifier.py"
    # Notify user
    notify-send "Netmon" "Network notifications stopped" --icon=dialog-information
    echo "Netmon notifier stopped"
else
    # If it's not running, start it and send to background
    cd /home/gabriwar/scripts/netmon
    python notifier.py &
    # Notify user
    notify-send "Netmon" "Network notifications restarted" --icon=dialog-information
    echo "Netmon notifier started"
fi
