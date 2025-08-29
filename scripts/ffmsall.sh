#!/bin/bash

# Checa se o nome do arquivo foi passado como argumento
if [ -z "$1" ]; then
	echo "Use assim: ./comp.sh arquivo.mp4"
	exit 1
fi

input_file="$1"
# Cria o nome do arquivo de saída adicionando _small
output_file="${input_file%.*}_small.${input_file##*.}"

# Checa se o arquivo de entrada existe
if [ ! -f "$input_file" ]; then
	echo "O arquivo '$input_file' não existe! 😭"
	exit 1
fi

# Pega o tamanho original do arquivo em bytes
original_size=$(du -b "$input_file" | awk '{print $1}')
original_size_mb=$(awk "BEGIN {printf \"%.2f\", $original_size/1024/1024}")

echo "Começando a compactar o seu vídeo!🎬"

# Executa o comando do ffmpeg
ffmpeg -i "$input_file" -c:v libx264 -crf 28 -preset fast -c:a aac -b:a 128k "$output_file" -y >/dev/null 2>&1

# Pega o novo tamanho do arquivo
new_size=$(du -b "$output_file" | awk '{print $1}')
new_size_mb=$(awk "BEGIN {printf \"%.2f\", $new_size/1024/1024}")

# Calcula a diferença de tamanho e a porcentagem de redução
size_difference_mb=$(awk "BEGIN {printf \"%.2f\", $original_size_mb - $new_size_mb}")
reduction_percentage=$(awk "BEGIN {printf \"%.2f\", ($size_difference_mb / $original_size_mb) * 100}")

echo "---"

# Imprime os resultados com um toque de carinho
echo "Tamanho original: ${original_size_mb} MB"
echo "Novo tamanho: ${new_size_mb} MB"
echo "O arquivo diminuiu ${reduction_percentage}% (ou ${size_difference_mb} MB)"
