#!/usr/bin/env sh
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ]; then
	hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
	killall -q waybar
	killall -q swww
	killall -q swww-daemon
	nbfc set -s 100
	exit
fi
hyprctl reload &
swww-daemon &
sh ~/scripts/waybar.sh &
nbfc set -a
exit
