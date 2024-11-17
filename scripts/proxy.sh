#!/bin/bash

# Default proxy settings
DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT="8080"

# Function to display usage
show_help() {
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo "  -e, --enable   Enable proxy"
	echo "  -d, --disable  Disable proxy"
	echo "  -h, --host     Proxy host (default: $DEFAULT_HOST)"
	echo "  -p, --port     Proxy port (default: $DEFAULT_PORT)"
	echo "  --help         Show this help message"
}

# Function to enable proxy
enable_proxy() {
	local host=$1
	local port=$2

	# Create backup of environment file if it doesn't exist
	if [ ! -f /etc/environment.bak ]; then
		sudo cp /etc/environment /etc/environment.bak
	fi

	# Set environment variables
	echo "Setting up proxy..."
	{
		echo "http_proxy=http://$host:$port/"
		echo "https_proxy=http://$host:$port/"
		echo "ftp_proxy=http://$host:$port/"
		echo "HTTP_PROXY=http://$host:$port/"
		echo "HTTPS_PROXY=http://$host:$port/"
		echo "FTP_PROXY=http://$host:$port/"
		echo "no_proxy=localhost,127.0.0.1,::1"
		echo "NO_PROXY=localhost,127.0.0.1,::1"
	} | sudo tee /etc/environment

	# Set up for current session
	export http_proxy="http://$host:$port/"
	export https_proxy="http://$host:$port/"
	export ftp_proxy="http://$host:$port/"
	export HTTP_PROXY="http://$host:$port/"
	export HTTPS_PROXY="http://$host:$port/"
	export FTP_PROXY="http://$host:$port/"
	export no_proxy="localhost,127.0.0.1,::1"
	export NO_PROXY="localhost,127.0.0.1,::1"

	echo "Proxy enabled successfully!"
	echo "Host: $host"
	echo "Port: $port"
}

# Function to disable proxy
disable_proxy() {
	# Restore original environment file if backup exists
	if [ -f /etc/environment.bak ]; then
		sudo mv /etc/environment.bak /etc/environment
	else
		# Clear environment file
		sudo truncate -s 0 /etc/environment
	fi

	# Unset proxy variables for current session
	unset http_proxy https_proxy ftp_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY no_proxy NO_PROXY

	echo "Proxy disabled successfully!"
}

# Parse command line arguments
HOST=$DEFAULT_HOST
PORT=$DEFAULT_PORT
ACTION=""

while [[ $# -gt 0 ]]; do
	case $1 in
	-e | --enable)
		ACTION="enable"
		shift
		;;
	-d | --disable)
		ACTION="disable"
		shift
		;;
	-h | --host)
		HOST="$2"
		shift 2
		;;
	-p | --port)
		PORT="$2"
		shift 2
		;;
	--help)
		show_help
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		show_help
		exit 1
		;;
	esac
done

# Execute requested action
if [ "$ACTION" == "enable" ]; then
	enable_proxy "$HOST" "$PORT"
elif [ "$ACTION" == "disable" ]; then
	disable_proxy
else
	echo "No action specified!"
	show_help
	exit 1
fi
