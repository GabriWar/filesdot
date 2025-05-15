toggle_process() {
	local process_name=$1
	local process_path=$2

	if pgrep -f "$process_path" >/dev/null; then
		echo "Stopping $process_name..."
		pkill -f "$process_path"
	else
		echo "Starting $process_name..."
		nohup "$process_path" &
	fi
}

toggle_process "Jackett" "/usr/lib/jackett/jackett"
toggle_process "FlareSolverr" "/opt/flaresolverr/flaresolverr"
toggle_process "Prowlarr" "/usr/lib/prowlarr/bin/Prowlarr"
#toggle_process "Radarr" "/usr/lib/radarr/bin/Radarr"
