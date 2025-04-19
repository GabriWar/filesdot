#!/bin/bash
on="󰑙"
off="󰑚"

# Check if the argument 'toggle' is passed
if [ "$1" == "toggle" ]; then
	if pgrep -x "gsr-ui" >/dev/null; then
		killall -SIGINT gsr-ui
		notify-send "Overlay disabled"

	fi
fi
if [ "$1" == "toggle" ]; then #check if not funning
	if ! pgrep -x "gsr-ui" >/dev/null; then
		gsr-ui >/dev/null 2>&1 &
		notify-send "Press ALT+Z to see overlay"
	fi
fi
if pgrep -x "gsr-ui" >/dev/null; then
	ONOFF=$on
	ONOFFSTRING="ON"
else
	ONOFF=$off
	ONOFFSTRING="OFF"
fi

echo "{ \"text\": \"$ONOFF\", \"tooltip\":\"REPLAY IS $ONOFFSTRING\nMOD+F12 save replay \nMOD+F11 toggle\"}"
