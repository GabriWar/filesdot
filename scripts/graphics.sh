#get the current mode with query
mode=$(envycontrol --query)

#if -n is passed will set envycontrol to nvidia

if [ "$1" == "-n" ]; then
	envycontrol -s nvidia
	exit 0
fi
#if -i is passed will set envycontrol to integtraed
if [ "$1" == "-i" ]; then
	envycontrol -s integrated
	exit 0
fi
#if -h is passed will set hybrid
if [ "$1" == "-h" ]; then
	envycontrol -s hybrid
	exit 0
fi

echo "{\"text\":\"$mode\",\"tooltip\":\"current mode: $mode\nclick to set mode to nvidia \nright click to set mode to hybrid\nmiddle click to set mode to integrated\n!!!REBOOT TO MAKE CHANGES!!!\"}"
