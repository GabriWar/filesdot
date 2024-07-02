#!/bin/bash

# Run the command passed as arguments
"$@"

# Capture the exit status of the command
exit_status=$?

# Check if the command ran successfully
if [ $exit_status -eq 0 ]; then
	notify-send "Command Finished" "Command '$*' executed successfully."
else
	notify-send "Command Failed" "Command '$*' failed with exit status $exit_status."
fi
