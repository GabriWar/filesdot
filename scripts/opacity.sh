#!/bin/bash

# Script para controlar opacidade da janela ativa
# Uso: opacity.sh [decrease|increase]

if [ "$#" -ne 1 ]; then
	echo "Uso: $0 [decrease|increase]"
	exit 1
fi

action="$1"
addr=$(hyprctl activewindow -j | jq -r '.address')
state_file="/tmp/opacity_$addr"

# Pega opacidade atual ou usa 1.0 como padrão
if [ -f "$state_file" ]; then
	current=$(cat "$state_file")
else
	current="1.0"
fi

# Calcula nova opacidade ou toggle blur
case "$action" in
"decrease")
	new_alpha=$(echo "$current - 0.1" | bc -l | awk '{if($1 < 0.1) print 0.1; else printf "%.1f", $1}')
	echo "$new_alpha" >"$state_file"
	hyprctl dispatch setprop address:$addr alpha $new_alpha
	hyprctl dispatch setprop address:$addr alphainactive $new_alpha
	echo "Opacidade: $current → $new_alpha"
	;;
"increase")
	new_alpha=$(echo "$current + 0.1" | bc -l | awk '{if($1 > 1.0) print 1.0; else printf "%.1f", $1}')
	echo "$new_alpha" >"$state_file"
	hyprctl dispatch setprop address:$addr alpha $new_alpha
	hyprctl dispatch setprop address:$addr alphainactive $new_alpha
	echo "Opacidade: $current → $new_alpha"
	;;
"toggle_blur")
	# Checa estado atual do blur
	if [ -f "$blur_state_file" ]; then
		blur_state=$(cat "$blur_state_file")
	else
		blur_state="0" # blur ativo por padrão
	fi

	if [ "$blur_state" = "0" ]; then
		# Blur está ativo, desativa
		hyprctl dispatch setprop address:$addr noblur 1
		echo "1" >"$blur_state_file"
		echo "Blur desativado"
	else
		# Blur está inativo, ativa
		hyprctl dispatch setprop address:$addr noblur 0
		echo "0" >"$blur_state_file"
		echo "Blur ativado"
	fi
	;;
*)
	echo "Ação inválida. Use 'decrease', 'increase' ou 'toggle_blur'"
	exit 1
	;;
esac
