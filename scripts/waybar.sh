#!/usr/bin/env bash
#start the thingy
. ~/.pyenv/versions/waybar/bin/activate
# Terminate already running bar instances

killall -q waybar

# Wait until the waybar processes have been shut down

while pgrep -x waybar >/dev/null; do sleep 1; done

# Launch main

waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &
