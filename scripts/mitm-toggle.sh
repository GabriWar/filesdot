#!/bin/bash

# Este script configura ou desfaz o modo proxy transparente (invisible mode)
# usando iptables para mitmproxy na sua máquina Arch Linux.
#
# Uso:
# Para ATIVAR: sudo ./mitm-toggle.sh --on
# Para DESATIVAR: sudo ./mitm-toggle.sh --off

# A porta que o mitmproxy está escutando no modo transparente.
# Verifique se corresponde ao que você usa.
PROXY_PORT="8080"

# Nome da cadeia NAT que será usada
MITM_CHAIN="MITM_PROXY_CHAIN"

# --- Funções ---

# Função para resetar/limpar as regras do iptables
reset_iptables() {
	echo "💖 Desativando o modo proxy transparente e limpando regras do iptables..."

	# 1. Remove o jump da cadeia OUTPUT
	# Usamos o -D (Delete) para remover a regra da cadeia OUTPUT
	if sudo iptables -t nat -C OUTPUT -p tcp -j ${MITM_CHAIN} 2>/dev/null; then
		sudo iptables -t nat -D OUTPUT -p tcp -j ${MITM_CHAIN}
	fi

	# (Opcional) Se você ativou o PREROUTING no seu sistema, descomente abaixo
	# if sudo iptables -t nat -C PREROUTING -p tcp -j ${MITM_CHAIN} 2>/dev/null; then
	#     sudo iptables -t nat -D PREROUTING -p tcp -j ${MITM_CHAIN}
	# fi

	# 2. Limpa e deleta a cadeia MITM
	sudo iptables -t nat -F ${MITM_CHAIN} 2>/dev/null
	sudo iptables -t nat -X ${MITM_CHAIN} 2>/dev/null

	# 3. Desativa o IP forwarding (Se você o ativou no sysctl temporariamente)
	# Cuidado: Se seu sistema precisa disso por outros motivos, não use esta linha
	# sudo sysctl -w net.ipv4.ip_forward=0

	echo "✅ Regras do iptables resetadas! O tráfego do sistema voltou ao normal."
}

# Função para configurar as regras do iptables
setup_iptables() {
	echo "🌟 Ativando o modo proxy transparente e configurando iptables..."

	# 1. Ativa o IP forwarding (necessário para o modo transparente)
	# Usamos sysctl -w para ativar apenas para a sessão atual
	sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null

	# 2. Reseta as regras antigas se a cadeia já existir
	sudo iptables -t nat -F ${MITM_CHAIN} 2>/dev/null
	sudo iptables -t nat -X ${MITM_CHAIN} 2>/dev/null

	# 3. Cria a cadeia NAT
	sudo iptables -t nat -N ${MITM_CHAIN}

	# 4. Regras para evitar loop e exclusões
	echo "   - Adicionando regras de exclusão..."
	sudo iptables -t nat -A ${MITM_CHAIN} -d 127.0.0.1/32 -j RETURN              # Exclui tráfego local
	sudo iptables -t nat -A ${MITM_CHAIN} -o lo -j RETURN                        # Exclui interface loopback
	sudo iptables -t nat -A ${MITM_CHAIN} -p tcp --dport ${PROXY_PORT} -j RETURN # Exclui tráfego para a porta do proxy

	# 5. Regras de Redirecionamento (HTTP e HTTPS)
	echo "   - Configurando redirecionamento para a porta ${PROXY_PORT}..."
	sudo iptables -t nat -A ${MITM_CHAIN} -p tcp --dport 80 -j REDIRECT --to-port ${PROXY_PORT}
	sudo iptables -t nat -A ${MITM_CHAIN} -p tcp --dport 443 -j REDIRECT --to-port ${PROXY_PORT}

	# 6. Aplica a cadeia MITM no tráfego de SAÍDA (seu sistema)
	echo "   - Aplicando as regras na cadeia OUTPUT..."
	sudo iptables -t nat -A OUTPUT -p tcp -j ${MITM_CHAIN}

	echo "✨ Configuração do iptables concluída! Você pode iniciar o mitmproxy agora."
	echo "Lembre-se de rodar: mitmproxy --mode transparent --listen-host 127.0.0.1"
}

# --- Lógica Principal do Script ---

if [ "$EUID" -ne 0 ]; then
	echo "🚨 Ops! Este script precisa ser executado com privilégios de root (sudo)."
	echo "Por favor, rode: sudo ./mitm-toggle.sh --on/--off"
	exit 1
fi

case "$1" in
--on)
	setup_iptables
	;;
--off)
	reset_iptables
	;;
*)
	echo "🤔 Modo de uso: sudo $0 --on | --off"
	exit 1
	;;
esac

exit 0
