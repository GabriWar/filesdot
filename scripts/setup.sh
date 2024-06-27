if [ "$EUID" -eq 0 ]; then
	echo "Please do not run as root"
	exit
fi
USRHOME=$HOME
mkdir $USRHOME/Pictures/Screenshots/ >>/dev/null 2>&1
mkdir $USRHOME/.cache/wal
mkdir $USRHOME/SHARE
sudo ln -s $USRHOME/SHARE /var/www
#chekc if line already exists
sudo echo "HandleLidSwitchExternalPower=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo echo "HandleLidSwitch=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf
