#!/bin/bash
on="󰑙"
off="󰑚"

# Check if the argument 'toggle' is passed
if [ "$1" == "toggle" ]; then
	if pgrep -x "gpu-screen-reco" >/dev/null; then
		killall -SIGINT gpu-screen-recorder
		notify-send "Stopping replay"

	else
		gpu-screen-recorder -r 120 -f 60 -w screen -o $HOME/Videos/ -c mp4 -q ultra -a "default_output|default_input" >/dev/null &
		notify-send "Starting replay"

	fi
fi

# Check if the argument 'save' is passed
if [ "$1" == "save" ]; then
	if pgrep -x "gpu-screen-reco" >/dev/null; then
		killall -SIGUSR1 gpu-screen-recorder
		notify-send "Saving replay"
	fi
fi

if pgrep -x "gpu-screen-reco" >/dev/null; then
	ONOFF=$on
	ONOFFSTRING="ON"
else
	ONOFF=$off
	ONOFFSTRING="OFF"
fi

echo "{ \"text\": \"$ONOFF\", \"tooltip\":\"REPLAY IS $ONOFFSTRING\nMOD+F12 save replay \nMOD+F11 toggle\"}"
