#! /usr/bin/bash
#
chosen=$(printf "󰐥 Power Off\n Restart\n󰤄 Suspend\n Log out" | rofi -dmenu -theme-str '* {font:"jetbrains mono 50";} configuration {show-icons:false;}')
case "$chosen" in
"󰐥 Power Off") shutdown now ;;
" Restart") reboot ;;
"󰒲 Suspend") systemctl suspend ;;
"󰋊 Hybernate") systemctl hibernate ;;
" Log out") hyprland exit ;;
*) exit 1 ;;
esac
