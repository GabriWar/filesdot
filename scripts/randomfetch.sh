#!/bin/bash
# Script to run fastfetch with a random logo from either image or ASCII folders

# Randomly choose between ascii_logos and image logos directories
if [ $((RANDOM % 2)) -eq 0 ] && [ "$(find ~/.config/fastfetch/ascii_logos -type f | wc -l)" -gt 0 ]; then
  # Choose from ASCII logos
  LOGO_PATH=$(find ~/.config/fastfetch/ascii_logos -type f | shuf -n 1)
  # For ASCII logos, use simpler command
  fastfetch --logo "$LOGO_PATH"
else
  # Choose from image logos
  LOGO_PATH=$(find ~/.config/fastfetch/logos -type f | shuf -n 1)
  # For image logos, use kitty-direct with sizing
  fastfetch --logo "$LOGO_PATH" --logo-type kitty-direct --logo-width 33 --logo-height 17 --logo-padding-top 1
fi
