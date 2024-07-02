#!/bin/bash
mkdir $HOME/.cache/wal 2>/dev/null
cd ~/Pictures/wallpapers || exit
#delete the cache if is more than half of the directory
if [ $(wc -l <~/.cache/wal/wallpapers) -gt $(ls | wc -l) / 2 ]; then
	rm -f ~/.cache/wal/wallpapers
fi
# Get a random wallpaper file, only jpg, png and gif files
wallpaper=$(ls | grep -E ".*\.(jpg|png|gif)" | shuf -n 1)
#check if the file is in the cache, if so we choose another
while grep -q $wallpaper ~/.cache/wal/wallpapers; do
	wallpaper=$(ls | grep -E ".*\.(jpg|png|gif)" | shuf -n 1)
done
echo $wallpaper >~/.cache/wal/wallpapers

#pick a random number between 0 and 1 to saturate the colorscheme
saturate=$(awk -v min=0.2 -v max=1.0 'BEGIN{srand(); print min+rand()*(max-min)}')
# Print the selected wallpaper
full_path=$(pwd)/$wallpaper
#if path is passed as argument skip the above
if [ -n "$1" ]; then
	full_path=$1
fi
rm -f ~/.config/hypr/hyprpaper.conf
echo "#this file is generated by randonwallsh each time you run it" >>~/.config/hypr/hyprpaper.conf
echo preload = $full_path >>~/.config/hypr/hyprpaper.conf
echo wallpaper = ,$full_path >>~/.config/hypr/hyprpaper.conf
echo splash = true >>~/.config/hypr/hyprpaper.conf
echo ipc = false >>~/.config/hypr/hyprpaper.conf
killall -q swww
swww img $full_path --transition-type random --transition-step 10 --transition-fps 90
wal --saturate $saturate -q -i $full_path -n -e
sh ~/.cache/wal/colors.sh
killall -q swaync
swaync &
