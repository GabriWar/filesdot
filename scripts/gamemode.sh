#!/usr/bin/env sh
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
echo $HYPRGAMEMODE
if [ "$HYPRGAMEMODE" = 1 ]; then
	hyprpm disable hyprfocus
	sleep 1
	hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:range 2;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:inactive_opacity 0.6\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword animation borderangle,0; \
	      keyword decoration:fullscreen_opacity 1;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
	killall -q waybar
	killall -q swww
	killall -q swww-daemon
	nbfc set -s 100
	hyprctl notify 1 5000 "rgb(40a02b)" "Gamemode [ON]"
	exit
fi
hyprctl reload &
sleep 1
swww-daemon &
sh ~/scripts/waybar.sh &
nbfc set -a
hyprctl notify 1 5000 "rgb(d20f39)" "Gamemode [OFF]"
exit
