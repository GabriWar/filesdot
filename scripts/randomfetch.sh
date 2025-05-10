#!/bin/bash
# Script to run fastfetch with a random logo from either image logos, ASCII logos, or Pokemon

# Randomly choose between three options: 0=ASCII, 1=Images, 2=Pokemon
CHOICE=$((RANDOM % 3))

# Check if pokeget is installed
if [ "$CHOICE" -eq 2 ] && ! command -v pokeget &> /dev/null; then
  echo "pokeget is not installed. Falling back to image logos."
  CHOICE=1
fi

if [ "$CHOICE" -eq 0 ] && [ "$(find ~/.config/fastfetch/ascii_logos -type f | wc -l)" -gt 0 ]; then
  # Choose from ASCII logos
  LOGO_PATH=$(find ~/.config/fastfetch/ascii_logos -type f | shuf -n 1)
  # For ASCII logos, use simpler command
  fastfetch --logo "$LOGO_PATH"
elif [ "$CHOICE" -eq 2 ]; then
  # Use pokeget to get a random Pokemon
  pokeget random | fastfetch --file-raw -
else
  # Choose from image logos (default option)
  LOGO_PATH=$(find ~/.config/fastfetch/logos -type f | shuf -n 1)
  # For image logos, use kitty-direct with sizing
  fastfetch --logo "$LOGO_PATH" --logo-type kitty-direct --logo-width 40 --logo-height 18 --logo-padding-top 1 --logo-padding-left 3
fi
