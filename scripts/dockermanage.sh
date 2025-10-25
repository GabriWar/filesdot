#!/bin/bash

# Script para gerenciar Docker - dockermanage.sh
# Lista imagens, containers, volumes e permite gerenciar eles

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para exibir cabeçalho
show_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        DOCKER MANAGEMENT SCRIPT${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
}

# Função para verificar se Docker está rodando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Erro: Docker não está rodando ou não está instalado!${NC}"
        exit 1
    fi
}

# Função para listar containers
list_containers() {
    echo -e "${BLUE}=== CONTAINERS ===${NC}"
    echo -e "${YELLOW}Status: Running | Stopped | All${NC}"
    echo
    
    # Containers rodando
    echo -e "${GREEN}CONTAINERS RODANDO:${NC}"
    if docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "CONTAINER ID"; then
        docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Nenhum container rodando"
    fi
    echo
    
    # Containers parados
    echo -e "${RED}CONTAINERS PARADOS:${NC}"
    if docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}" | grep -q "CONTAINER ID"; then
        docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}" | grep -v "Up"
    else
        echo "Nenhum container parado"
    fi
    echo
}

# Função para listar imagens
list_images() {
    echo -e "${BLUE}=== IMAGENS ===${NC}"
    echo
    if docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}" | grep -q "REPOSITORY"; then
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        echo "Nenhuma imagem encontrada"
    fi
    echo
}

# Função para listar volumes
list_volumes() {
    echo -e "${BLUE}=== VOLUMES ===${NC}"
    echo
    if docker volume ls --format "table {{.Driver}}\t{{.Name}}" | grep -q "DRIVER"; then
        docker volume ls --format "table {{.Driver}}\t{{.Name}}"
    else
        echo "Nenhum volume encontrado"
    fi
    echo
}

# Função para listar redes
list_networks() {
    echo -e "${BLUE}=== REDES ===${NC}"
    echo
    if docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | grep -q "NAME"; then
        docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    else
        echo "Nenhuma rede encontrada"
    fi
    echo
}

# Função para mostrar menu principal
show_menu() {
    echo -e "${PURPLE}=== MENU PRINCIPAL ===${NC}"
    echo "1. Listar todos os recursos"
    echo "2. Gerenciar containers"
    echo "3. Gerenciar imagens"
    echo "4. Gerenciar volumes"
    echo "5. Gerenciar redes"
    echo "6. Limpeza geral (remover recursos não utilizados)"
    echo -e "${RED}7. Limpeza COMPLETA (TUDO)${NC}"
    echo "8. Sair"
    echo
}

# Função para gerenciar containers
manage_containers() {
    while true; do
        echo -e "${PURPLE}=== GERENCIAR CONTAINERS ===${NC}"
        echo "1. Listar containers"
        echo "2. Executar container"
        echo "3. Parar container"
        echo "4. Iniciar container"
        echo "5. Reiniciar container"
        echo "6. Remover container"
        echo "7. Ver logs do container"
        echo "8. Configurar restart policy"
        echo "9. Voltar ao menu principal"
        echo
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                list_containers
                ;;
            2)
                echo "Containers disponíveis:"
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    echo "Iniciando container $container_id..."
                    docker start $container_id
                fi
                ;;
            3)
                echo "Containers rodando:"
                docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    echo "Parando container $container_id..."
                    docker stop $container_id
                fi
                ;;
            4)
                echo "Containers parados:"
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" | grep -v "Up"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    echo "Iniciando container $container_id..."
                    docker start $container_id
                fi
                ;;
            5)
                echo "Containers disponíveis:"
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    echo "Reiniciando container $container_id..."
                    docker restart $container_id
                fi
                ;;
            6)
                echo "Containers disponíveis:"
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    read -p "Tem certeza que deseja remover o container $container_id? (y/N): " confirm
                    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                        echo "Removendo container $container_id..."
                        docker rm $container_id
                    fi
                fi
                ;;
            7)
                echo "Containers disponíveis:"
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    echo "Mostrando logs do container $container_id (Ctrl+C para sair):"
                    docker logs -f $container_id
                fi
                ;;
            8)
                echo "Containers disponíveis:"
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
                echo
                read -p "Digite o ID ou nome do container: " container_id
                if [ ! -z "$container_id" ]; then
                    echo "Políticas de restart disponíveis:"
                    echo "1. no - Não reiniciar automaticamente"
                    echo "2. on-failure - Reiniciar apenas em caso de falha"
                    echo "3. always - Sempre reiniciar"
                    echo "4. unless-stopped - Reiniciar sempre, exceto se parado manualmente"
                    echo
                    read -p "Escolha a política (1-4): " policy_choice
                    
                    case $policy_choice in
                        1) policy="no" ;;
                        2) policy="on-failure" ;;
                        3) policy="always" ;;
                        4) policy="unless-stopped" ;;
                        *) echo "Opção inválida"; continue ;;
                    esac
                    
                    echo "Configurando restart policy '$policy' para container $container_id..."
                    docker update --restart=$policy $container_id
                fi
                ;;
            9)
                break
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac
        echo
    done
}

# Função para gerenciar imagens
manage_images() {
    while true; do
        echo -e "${PURPLE}=== GERENCIAR IMAGENS ===${NC}"
        echo "1. Listar imagens"
        echo "2. Remover imagem"
        echo "3. Remover imagens não utilizadas"
        echo "4. Baixar imagem"
        echo "5. Voltar ao menu principal"
        echo
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                list_images
                ;;
            2)
                echo "Imagens disponíveis:"
                docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
                echo
                read -p "Digite o ID ou nome da imagem: " image_id
                if [ ! -z "$image_id" ]; then
                    read -p "Tem certeza que deseja remover a imagem $image_id? (y/N): " confirm
                    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                        echo "Removendo imagem $image_id..."
                        docker rmi $image_id
                    fi
                fi
                ;;
            3)
                read -p "Tem certeza que deseja remover imagens não utilizadas? (y/N): " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    echo "Removendo imagens não utilizadas..."
                    docker image prune -f
                fi
                ;;
            4)
                read -p "Digite o nome da imagem para baixar (ex: nginx:latest): " image_name
                if [ ! -z "$image_name" ]; then
                    echo "Baixando imagem $image_name..."
                    docker pull $image_name
                fi
                ;;
            5)
                break
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac
        echo
    done
}

# Função para gerenciar volumes
manage_volumes() {
    while true; do
        echo -e "${PURPLE}=== GERENCIAR VOLUMES ===${NC}"
        echo "1. Listar volumes"
        echo "2. Remover volume"
        echo "3. Remover volumes não utilizados"
        echo "4. Voltar ao menu principal"
        echo
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                list_volumes
                ;;
            2)
                echo "Volumes disponíveis:"
                docker volume ls --format "table {{.Driver}}\t{{.Name}}"
                echo
                read -p "Digite o nome do volume: " volume_name
                if [ ! -z "$volume_name" ]; then
                    read -p "Tem certeza que deseja remover o volume $volume_name? (y/N): " confirm
                    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                        echo "Removendo volume $volume_name..."
                        docker volume rm $volume_name
                    fi
                fi
                ;;
            3)
                read -p "Tem certeza que deseja remover volumes não utilizados? (y/N): " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    echo "Removendo volumes não utilizados..."
                    docker volume prune -f
                fi
                ;;
            4)
                break
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac
        echo
    done
}

# Função para gerenciar redes
manage_networks() {
    while true; do
        echo -e "${PURPLE}=== GERENCIAR REDES ===${NC}"
        echo "1. Listar redes"
        echo "2. Remover rede"
        echo "3. Remover redes não utilizadas"
        echo "4. Voltar ao menu principal"
        echo
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                list_networks
                ;;
            2)
                echo "Redes disponíveis:"
                docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
                echo
                read -p "Digite o nome da rede: " network_name
                if [ ! -z "$network_name" ]; then
                    read -p "Tem certeza que deseja remover a rede $network_name? (y/N): " confirm
                    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                        echo "Removendo rede $network_name..."
                        docker network rm $network_name
                    fi
                fi
                ;;
            3)
                read -p "Tem certeza que deseja remover redes não utilizadas? (y/N): " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    echo "Removendo redes não utilizadas..."
                    docker network prune -f
                fi
                ;;
            4)
                break
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac
        echo
    done
}

# Função para limpeza geral
cleanup_docker() {
    echo -e "${PURPLE}=== LIMPEZA GERAL ===${NC}"
    echo "Esta opção irá remover:"
    echo "- Containers parados"
    echo "- Redes não utilizadas"
    echo "- Volumes não utilizados"
    echo "- Imagens não utilizadas"
    echo "- Cache de build"
    echo
    read -p "Tem certeza que deseja executar a limpeza? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        echo "Executando limpeza geral..."
        docker system prune -a --volumes -f
        echo "Limpeza concluída!"
    fi
}

# Função para limpeza COMPLETA - TUDO
cleanup_all_docker() {
    echo -e "${RED}=== LIMPEZA COMPLETA - TUDO ===${NC}"
    echo -e "${RED}ATENÇÃO: Esta opção irá remover ABSOLUTAMENTE TUDO:${NC}"
    echo "- Todos os containers (rodando e parados)"
    echo "- Todas as imagens"
    echo "- Todos os volumes"
    echo "- Todas as redes"
    echo "- Todo o cache do sistema"
    echo
    echo -e "${YELLOW}Esta ação é IRREVERSÍVEL!${NC}"
    echo
    read -p "Tem CERTEZA ABSOLUTA que deseja executar a limpeza COMPLETA? Digite 'TUDO' para confirmar: " confirm
    if [[ $confirm == "TUDO" ]]; then
        echo -e "${RED}Executando limpeza COMPLETA...${NC}"
        echo
        
        echo "1. Parando todos os containers..."
        docker stop $(docker ps -a -q) 2>/dev/null || echo "Nenhum container para parar"
        
        echo "2. Removendo todos os containers..."
        docker rm $(docker ps -a -q) 2>/dev/null || echo "Nenhum container para remover"
        
        echo "3. Removendo todas as imagens..."
        docker rmi $(docker images -a -q) 2>/dev/null || echo "Nenhuma imagem para remover"
        
        echo "4. Limpando sistema completo (volumes, redes, cache)..."
        docker system prune -a --volumes -f
        
        echo
        echo -e "${GREEN}Limpeza COMPLETA concluída! TUDO foi removido!${NC}"
    else
        echo -e "${YELLOW}Limpeza cancelada.${NC}"
    fi
}

# Função principal
main() {
    show_header
    check_docker
    
    while true; do
        show_menu
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                list_containers
                list_images
                list_volumes
                list_networks
                ;;
            2)
                manage_containers
                ;;
            3)
                manage_images
                ;;
            4)
                manage_volumes
                ;;
            5)
                manage_networks
                ;;
            6)
                cleanup_docker
                ;;
            7)
                cleanup_all_docker
                ;;
            8)
                echo -e "${GREEN}Saindo... Até logo!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida! Tente novamente.${NC}"
                ;;
        esac
        echo
        read -p "Pressione Enter para continuar..."
        clear
        show_header
    done
}

# Executar função principal
main