#! /usr/bin/bash
#
chosen=$(printf "󰐥 Power Off\n Restart\n󰤄 Suspend\n Log out" | rofi -dmenu -i -l 3 -width 50 -font "System San Francisco Display 10")
case "$chosen" in
"󰐥 Power Off") shutdown now ;;
" Restart") reboot ;;
"󰒲 Suspend") systemctl suspend ;;
"󰋊 Hybernate") systemctl hibernate ;;
" Log out") hyprland exit ;;
*) exit 1 ;;
esac
