#!/bin/bash

print_usage() {
	echo "Usage: $0 [-g] [-c] [-l]"
	echo "  -g: Show GPU usage and temperature"
	echo "  -c: Show CPU usage and temperature"
	echo "  -l: Loop mode - refresh data every second"
	echo "  (no args): Show GPU temperature only (legacy mode)"
	exit 1
}

# Default mode (legacy behavior)
show_gpu=false
show_cpu=false
loop_mode=false

# Parse command line arguments
while getopts "gcl" opt; do
	case ${opt} in
	g)
		show_gpu=true
		;;
	c)
		show_cpu=true
		;;
	l)
		loop_mode=true
		;;
	\?)
		print_usage
		;;
	esac
done

# If no arguments provided, default to legacy mode (GPU temp only)
if [ $OPTIND -eq 1 ]; then
	show_gpu=true
fi

# Initialize variables
text=""
tooltip=""

# GPU information
if $show_gpu; then
	# Check if nvidia-smi is available
	if ! command -v nvidia-smi &>/dev/null; then
		echo "{ \"text\": \"GPU N/A\", \"tooltip\":\"Error: nvidia-smi command not found.\"}"
		exit 1
	fi

	# Get GPU temperature
	gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1 | tr -d ' ')

	# Get GPU utilization percentage
	gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1 | tr -d ' ')

	# Get individual GPU details including usage
	gpu_detailed_info=$(nvidia-smi --query-gpu=index,name,utilization.gpu,utilization.memory,temperature.gpu,memory.used,memory.total,fan.speed --format=csv)

	text="${gpu_usage}%|${gpu_temp}°"
	tooltip="${gpu_detailed_info}"
fi

# CPU information
if $show_cpu; then
	# Get CPU temperature (using sensors command)
	if command -v sensors &>/dev/null; then
		# Try to get CPU temperature, different systems have different sensor outputs
		# Try with k10temp (AMD) first
		cpu_temp=$(sensors | grep -i "Tctl:" | awk '{print $2}' | tr -d '+°C')

		# If not found, try with coretemp (Intel)
		if [ -z "$cpu_temp" ]; then
			cpu_temp=$(sensors | grep -i "Package id 0:" | awk '{print $4}' | tr -d '+°C')
		fi

		# If still not found, try a more generic approach
		if [ -z "$cpu_temp" ]; then
			cpu_temp=$(sensors | grep -i "cpu" | head -n 1 | awk '{print $2}' | tr -d '+°C')
		fi

		# Get all CPU core temperatures
		cpu_core_temps=$(sensors | grep -E 'Core [0-9]+:' | awk '{printf "Core %s: %s\n", $2, $3}' | tr -d ':')
	else
		cpu_temp="N/A"
		cpu_core_temps="N/A"
	fi

	# Get CPU usage percentage
	cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')

	# Get per-core CPU usage
	cpu_cores_usage=$(mpstat -P ALL 1 1 | awk '/^Average:/ && $2 ~ /[0-9]/ {printf "Core %s: %.1f%%\n", $2, 100-$12}')
	if [ -z "$cpu_cores_usage" ]; then
		# If mpstat isn't available, try with top
		cpu_cores_usage=$(top -bn1 | grep -A$(nproc) '%Cpu' | grep -v 'Cpu(s)' | awk '{printf "Core %d: %.1f%%\n", NR-1, $2+$4}')
	fi

	# Get detailed CPU info for tooltip
	full_cpu_output=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d ':' -f 2 | sed 's/^[ \t]*//')
	full_cpu_output="${full_cpu_output}\n\n$(top -bn1 | head -7)"
	full_cpu_output="${full_cpu_output}
  --- CPU CORE USAGE ---
  ${cpu_cores_usage}
  --- CPU CORE TEMPERATURES ---
  ${cpu_core_temps}"

	text="${cpu_usage}%|${cpu_temp}°"
	tooltip="${full_cpu_output}"

	# If both CPU and GPU are shown, combine them
	if $show_gpu; then
		text="CPU: ${cpu_usage}%|${cpu_temp}° | GPU: ${gpu_usage}%|${gpu_temp}°"
		tooltip="CPU Info:\n${full_cpu_output}\n\nGPU Info:\n${full_gpu_output}"
	fi
fi

# Function to generate the output
generate_output() {
	# Initialize class array for CSS styling in waybar
	classes=()

	# Check CPU temperature and usage if CPU is being monitored
	if $show_cpu; then
		# Add class for high CPU temperature (over 70°C)
		if [[ "$cpu_temp" != "N/A" && $(echo "$cpu_temp > 90" | bc -l) -eq 1 ]]; then
			classes+=("hot")
		fi

		# Add class for high CPU usage (over 70%)
		if [[ "$cpu_usage" != "N/A" && $(echo "$cpu_usage > 70" | bc -l) -eq 1 ]]; then
			classes+=("usage")
		fi
	fi

	# Check GPU temperature and usage if GPU is being monitored
	if $show_gpu; then
		# Add class for high GPU temperature (over 70°C)
		if [[ "$gpu_temp" != "N/A" && $(echo "$gpu_temp > 70" | bc -l) -eq 1 ]]; then
			classes+=("hot")
		fi

		# Add class for high GPU usage (over 70%)
		if [[ "$gpu_usage" != "N/A" && $(echo "$gpu_usage > 70" | bc -l) -eq 1 ]]; then
			classes+=("usage")
		fi
	fi

	# Create the class string for the JSON output
	class_string=""
	if [ ${#classes[@]} -gt 0 ]; then
		class_string="\"class\": \"${classes[*]}\", "
	fi

	# Properly escape tooltip content for JSON
	escaped_tooltip=$(echo "$tooltip" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

	# Output the JSON with optional class property
	echo "{ ${class_string}\"text\": \"$text\", \"tooltip\":\"$escaped_tooltip\"}"
}

# Loop mode or single output
if $loop_mode; then
	# In loop mode, print complete JSON objects on separate lines
	# This is the format waybar expects
	while true; do # Update data before generating output
		if $show_gpu; then
			# Update all GPU information
			full_gpu_output=$(nvidia-smi)
			gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1 | tr -d ' ')
			gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1 | tr -d ' ')
			# Update detailed GPU info for tooltip
			gpu_detailed_info=$(nvidia-smi --query-gpu=index,name,utilization.gpu,utilization.memory,temperature.gpu,memory.used,memory.total,fan.speed --format=csv)

			text="${gpu_usage}%|${gpu_temp}°"
			tooltip="${gpu_detailed_info}"
		fi

		if $show_cpu; then
			if command -v sensors &>/dev/null; then
				cpu_temp=$(sensors | grep -i "Tctl:" | awk '{print $2}' | tr -d '+°C')
				if [ -z "$cpu_temp" ]; then
					cpu_temp=$(sensors | grep -i "Package id 0:" | awk '{print $4}' | tr -d '+°C')
				fi
				if [ -z "$cpu_temp" ]; then
					cpu_temp=$(sensors | grep -i "cpu" | head -n 1 | awk '{print $2}' | tr -d '+°C')
				fi

				# Update CPU core temperatures
				cpu_core_temps=$(sensors | grep -E 'Core [0-9]+:' | awk '{printf "Core %s: %s\n", $2, $3}' | tr -d ':')
			else
				cpu_temp="N/A"
				cpu_core_temps="N/A"
			fi

			# Update CPU usage data
			cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')

			# Update per-core CPU usage
			cpu_cores_usage=$(mpstat -P ALL 1 1 | awk '/^Average:/ && $2 ~ /[0-9]/ {printf "Core %s: %.1f%%\n", $2, 100-$12}')
			if [ -z "$cpu_cores_usage" ]; then
				# If mpstat isn't available, try with top
				cpu_cores_usage=$(top -bn1 | grep -A$(nproc) '%Cpu' | grep -v 'Cpu(s)' | awk '{printf "Core %d: %.1f%%\n", NR-1, $2+$4}')
			fi

			# Get detailed CPU info for tooltip
			full_cpu_output=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d ':' -f 2 | sed 's/^[ \t]*//')
			full_cpu_output="${full_cpu_output}\n\n$(top -bn1 | head -7)"
			full_cpu_output="${full_cpu_output}
      --- CPU CORE USAGE ---
      ${cpu_cores_usage}
      --- CPU CORE TEMPERATURES ---
      ${cpu_core_temps}"

			text="${cpu_usage}%|${cpu_temp}°"
			tooltip="${full_cpu_output}"

			if $show_gpu; then
				text="CPU: ${cpu_usage}%|${cpu_temp}° | GPU: ${gpu_usage}%|${gpu_temp}°"
				tooltip="CPU Info:\n${full_cpu_output}\n\nGPU Info:\n${full_gpu_output}"
			fi
		fi

		generate_output
		sleep 1
	done
else
	# Format the output as JSON for waybar (single run)
	generate_output
fi
