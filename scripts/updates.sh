#check if the temp files exist
if [ -f /tmp/pendingupdates ]; then
	rm /tmp/pendingupdates
fi
if [ -f /tmp/flatpakupdates ]; then
	rm /tmp/flatpakupdates
fi
if [ -f /tmp/snapupdates ]; then
	rm /tmp/snapupdates
fi
#if -u is passed update the system
if [ "$1" = "-u" ]; then
	paru -Syu --noconfirm
	if [ -x "$(command -v flatpak)" ]; then
		flatpak update -y
	fi
	if [ -x "$(command -v snap)" ]; then
		snap refresh
	fi
	sh ~/.config/waybar/scripts/waybar.sh &
	echo "System updated"
	echo "press enter to close"
	read -r
	exit
fi

# Arch updates
echo " Arch:" >>/tmp/pendingupdates
archup=$(checkupdates)
numarch=$(echo "$archup" | wc -l)
echo "$numarch" >>/tmp/pendingupdates
echo "$archup" >>/tmp/pendingupdates

#test if flatpak is installed ad save  the number of updates on flatpak
# if [ -x "$(command -v flatpak)" ]; then
# 	echo "Flatpak:" >>/tmp/pendingupdates
# 	flatpakup=$(flatpak update --appstream -y)
# 	numflatpak=$(echo "$flatpakup" | wc -l)
# 	echo "$numflatpak" >>/tmp/pendingupdates
# 	echo "$flatpakup" >>/tmp/pendingupdates
# fi

#test if snap is installed and save the number of updates on snap
# if [ -x "$(command -v snap)" ]; then
# 	echo "Snap:" >>/tmp/pendingupdates
# 	snapup=$(snap refresh --list)
# 	numsnap=$(echo "$snapup" | wc -l)
# 	echo "$numsnap" >>/tmp/pendingupdates
# 	echo "$snapup" >>/tmp/pendingupdates
# 	snap refresh --list >>/tmp/pendingupdates
# fi
#
# AUR updates
echo "AUR:" >>/tmp/pendingupdates
aurup=$(paru -Qu)
numaur=$(echo "$aurup" | wc -l)
echo "$numaur" >>/tmp/pendingupdates
echo "$aurup" >>/tmp/pendingupdates

#return the sum of the updates if -s is passed
sum=$(($numarch + $numaur - 2))
if [ "$1" = "-s" ]; then
	echo "$sum"
fi
tooltip=$(cat /tmp/pendingupdates)
#if j is passed return as json
if [ "$1" = "-j" ]; then
	if [ $sum -eq 0 ]; then
		echo "{\"text\":\"\", \"tooltip\":\"No updates available\",\"class\":\"empty\"}"
	fi
	#if not equals to zero
	if [ $sum -ne 0 ]; then
		#remove breaklines and colors from tooltip to return as json
		tooltip=$(echo "$tooltip" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
		tooltip=$(echo "$tooltip" | sed 's/$/\\n/g')
		tooltip=$(echo "$tooltip" | tr '\n' ' ')
		echo "{\"text\":\"$sum\", \"tooltip\":\"$tooltip\"}"
	fi
fi
