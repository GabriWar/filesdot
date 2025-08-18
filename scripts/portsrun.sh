#!/bin/bash
# checkports.sh
# Show processes using ports

if [ "$1" ]; then
	# Check specific port
	PORT="$1"
	echo "🔍 Checking port $PORT..."
	sudo ss -ltnp | grep ":$PORT " || echo "No process found on port $PORT"
else
	# Show all listening ports with process info
	echo "📡 Listing all listening ports..."
	sudo ss -ltnp
fi
