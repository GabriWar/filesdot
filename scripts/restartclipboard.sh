killall wl-paste
killall cliphist
##clear
cliphist wipe

wl-paste --type text --watch cliphist store  #Stores only text data
wl-paste --type image --watch cliphist store #Stores only image data
wl-paste --type file --watch cliphist store  #Stores only file data
notify-send "Clipboard history restarted"
