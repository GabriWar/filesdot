FILE="$HOME/.config/hypr/hyprland.conf"
HINT1=$(grep "bind" "$FILE" | shuf -n 1)
HINT2=$(grep "bind" ~/.config/terminalrcs/fishkeybinds.txt | shuf -n 1)
echo -e "Hyprland: $HINT1\nFish: $HINT2" | boxes --color -d ansi-rounded
