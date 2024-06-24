#!/bin/bash

# Change to the wallpapers directory
cd ~/Pictures/wallpapers || exit
#remove spaces
for file in *\ *; do mv "$file" "${file// /_}"; done

# Get a random wallpaper file
wallpaper=$(ls | shuf -n 1)

#pick a random number between 0 and 1 to saturate the colorscheme
saturate=$(awk -v min=0.2 -v max=1.0 'BEGIN{srand(); print min+rand()*(max-min)}')

# Print the selected wallpaper
full_path=$(pwd)/$wallpaper

rm -f ~/.config/hypr/hyprpaper.conf
echo "#this file is generated by randonwallsh each time you run it" >>~/.config/hypr/hyprpaper.conf
echo preload = $full_path >>~/.config/hypr/hyprpaper.conf
echo wallpaper = ,$full_path >>~/.config/hypr/hyprpaper.conf
echo splash = true >>~/.config/hypr/hyprpaper.conf
echo ipc = false >>~/.config/hypr/hyprpaper.conf
killall -q hyprpaper
hyprpaper -c ~/.config/hypr/hyprpaper.conf &
wal --saturate $saturate -q -i $full_path -n
echo $full_path
echo $saturate
echo $wallpaper
