if [ "$EUID" -eq 0 ]; then
	echo "Please do not run as root"
	exit
fi
USRHOME=$HOME
mkdir $USRHOME/Pictures/Screenshots/ >>/dev/null 2>&1
mkdir $USRHOME/.cache/wal
mkdir $USRHOME/SHARE
cd $USRHOME/scripts || exit
git clone https://github.com/giomatfois62/rofi-desktop.git
#chekc if line already exists
sudo echo "HandleLidSwitchExternalPower=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo echo "HandleLidSwitch=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo echo "kernel.sysrq = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
cd $USRHOME/.config/waybar/ || exit
git clone https://github.com/gabriwar/waybar-mediaplayer
cd waybar-mediaplayer || exit
pyenv install 3.12.0
git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
pyenv virtualenv 3.12.0 waybar
pyenv activate waybar
pip3 install -r requirements.txt
sudo systemctl enable nbfc
sudo systemctl start nbfc
sudo touch /etc/modprobe.d/99-custom-no-logitech-driver.conf
sudo echo "blacklist hid_logitech_dj" | sudo tee -a /etc/modprobe.d/99-custom-no-logitech-driver.conf
sudo echo "blacklist hid_logitech_hidpp" | sudo tee -a /etc/modprobe.d/99-custom-no-logitech-driver.conf
if [ -f "$USRHOME/scripts/entries.sh" ]; then
	sudo $USRHOME/scripts/entries.sh
fi
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
hyprpm add https://github.com/pyt0xic/hyprfocus
hyprpm enable hyprfocus
hyprpm enable dynamic-cursors
gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
gsettings set org.gnome.desktop.interface icon-theme "Papyrus-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" # for GTK4 apps
