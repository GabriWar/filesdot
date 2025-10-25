#!/usr/bin/env bash

# MITM Traffic Interceptor
# Intercepts and decrypts traffic from specific programs or system-wide

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROXY_PORT=8080
MITM_LOG_DIR="$HOME/.mitm-logs"
MITMPROXY_DIR="$HOME/.mitmproxy"
MITM_TOOL="${MITM_TOOL:-mitmweb}"  # Default tool: mitmproxy, mitmweb, or mitmdump

# Create log directory
mkdir -p "$MITM_LOG_DIR"

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║     MITM Traffic Interceptor          ║"
    echo "║     Decrypt & Inspect All Traffic     ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 program <command>    - Intercept traffic from a specific program"
    echo "  $0 -p [search]          - Fuzzy find and select a program to intercept"
    echo "  $0 -r [search]          - Fuzzy find running process and intercept it"
    echo "  $0 system               - Intercept all system traffic"
    echo "  $0 install-cert         - Install mitmproxy CA certificate"
    echo "  $0 stop                 - Stop system-wide interception"
    echo "  $0 reset                - Reset proxy and remove SSL certificates"
    echo ""
    echo -e "${YELLOW}Tool Selection (set MITM_TOOL env var):${NC}"
    echo "  MITM_TOOL=mitmproxy     - Terminal UI (interactive, keyboard navigation)"
    echo "  MITM_TOOL=mitmweb       - Web interface at http://127.0.0.1:8081 (default)"
    echo "  MITM_TOOL=mitmdump      - Command-line only (no UI, just logs)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 program curl https://example.com"
    echo "  $0 program firefox"
    echo "  $0 -p                   - Interactive program selection"
    echo "  $0 -p firefox           - Fuzzy search for 'firefox'"
    echo "  $0 -r                   - Interactive running process selection"
    echo "  $0 -r chrome            - Fuzzy search running processes for 'chrome'"
    echo "  MITM_TOOL=mitmproxy $0 system"
    echo "  $0 reset"
    echo ""
}

check_requirements() {
    local missing=()
    local check_fzf="${1:-false}"

    if ! command -v mitmproxy &> /dev/null && ! command -v mitmdump &> /dev/null; then
        missing+=("mitmproxy")
    fi

    if ! command -v iptables &> /dev/null; then
        missing+=("iptables")
    fi

    if [ "$check_fzf" = "true" ] && ! command -v fzf &> /dev/null; then
        missing+=("fzf")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing required tools: ${missing[*]}${NC}"
        echo -e "${YELLOW}Install with: sudo pacman -S ${missing[*]}${NC}"
        exit 1
    fi
}

fuzzy_find_program() {
    local query="$1"

    echo -e "${GREEN}[+] Searching for programs...${NC}"

    # Get all executables from PATH
    local programs=$(
        IFS=:
        for dir in $PATH; do
            [ -d "$dir" ] && find "$dir" -maxdepth 1 -type f -executable 2>/dev/null
        done | xargs -n1 basename 2>/dev/null | sort -u
    )

    # Use fzf to select a program
    local selected
    if [ -n "$query" ]; then
        selected=$(echo "$programs" | fzf --query="$query" --select-1 --exit-0 \
            --height=50% \
            --border \
            --prompt="Select program to intercept: " \
            --preview="which {} 2>/dev/null || echo 'Not in PATH'" \
            --preview-window=right:50%:wrap)
    else
        selected=$(echo "$programs" | fzf \
            --height=50% \
            --border \
            --prompt="Select program to intercept: " \
            --preview="which {} 2>/dev/null || echo 'Not in PATH'" \
            --preview-window=right:50%:wrap)
    fi

    if [ -z "$selected" ]; then
        echo -e "${RED}[-] No program selected${NC}"
        exit 1
    fi

    echo "$selected"
}

intercept_fuzzy_program() {
    local query="$1"

    # Find the program
    local program=$(fuzzy_find_program "$query")

    echo -e "${GREEN}[+] Selected program: $program${NC}"
    echo ""

    # Ask for additional arguments
    echo -e "${YELLOW}[?] Enter additional arguments for $program (or press Enter for none):${NC}"
    read -r args

    # Build the command
    if [ -n "$args" ]; then
        intercept_program "$program" $args
    else
        intercept_program "$program"
    fi
}

fuzzy_find_process() {
    local query="$1"

    echo -e "${GREEN}[+] Scanning running processes...${NC}"

    # Get running processes with details (PID, user, command)
    local processes=$(ps aux --sort=-%mem | awk 'NR>1 {printf "%s|%s|%s|", $2, $1, $11; for(i=12;i<=NF;i++) printf "%s ", $i; printf "\n"}')

    # Use fzf to select a process
    local selected
    if [ -n "$query" ]; then
        selected=$(echo "$processes" | fzf --query="$query" --select-1 --exit-0 \
            --height=80% \
            --border \
            --prompt="Select process to intercept: " \
            --delimiter="|" \
            --with-nth=3 \
            --preview="echo 'PID: {1}'; echo 'User: {2}'; echo 'Command: {3}'; echo ''; ps -p {1} -o pid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command 2>/dev/null | tail -n +2" \
            --preview-window=right:50%:wrap)
    else
        selected=$(echo "$processes" | fzf \
            --height=80% \
            --border \
            --prompt="Select process to intercept: " \
            --delimiter="|" \
            --with-nth=3 \
            --preview="echo 'PID: {1}'; echo 'User: {2}'; echo 'Command: {3}'; echo ''; ps -p {1} -o pid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command 2>/dev/null | tail -n +2" \
            --preview-window=right:50%:wrap)
    fi

    if [ -z "$selected" ]; then
        echo -e "${RED}[-] No process selected${NC}"
        exit 1
    fi

    # Parse the selection
    local pid=$(echo "$selected" | cut -d'|' -f1)
    local user=$(echo "$selected" | cut -d'|' -f2)
    local cmd=$(echo "$selected" | cut -d'|' -f3)

    echo "$pid|$user|$cmd"
}

intercept_running_process() {
    local query="$1"

    # Find the process
    local selection=$(fuzzy_find_process "$query")

    local pid=$(echo "$selection" | cut -d'|' -f1)
    local user=$(echo "$selection" | cut -d'|' -f2)
    local cmd=$(echo "$selection" | cut -d'|' -f3)

    echo -e "${GREEN}[+] Selected process:${NC}"
    echo -e "${BLUE}    PID: $pid${NC}"
    echo -e "${BLUE}    User: $user${NC}"
    echo -e "${BLUE}    Command: $cmd${NC}"
    echo ""

    # Get the executable path
    local exe_path=$(readlink -f "/proc/$pid/exe" 2>/dev/null)

    if [ -z "$exe_path" ] || [ ! -x "$exe_path" ]; then
        echo -e "${RED}[-] Cannot determine executable path for PID $pid${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[!] To intercept traffic from a running process, we need to:${NC}"
    echo "    1. Kill the current process (PID: $pid)"
    echo "    2. Restart it through the MITM proxy"
    echo ""
    echo -e "${YELLOW}[?] Do you want to proceed? (y/N):${NC}"
    read -r -n 1 confirm
    echo

    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[*] Cancelled${NC}"
        exit 0
    fi

    # Get process arguments
    echo -e "${GREEN}[+] Getting process arguments...${NC}"
    local cmdline=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null)

    # Extract just the arguments (everything after the executable)
    local args=$(echo "$cmdline" | sed "s|^$exe_path ||")

    echo -e "${YELLOW}[*] Original command: $cmdline${NC}"
    echo -e "${YELLOW}[?] Edit arguments before restart? (y/N):${NC}"
    read -r -n 1 edit_args
    echo

    if [[ $edit_args =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[?] Enter arguments for $exe_path:${NC}"
        read -r args
    fi

    # Kill the process
    echo -e "${YELLOW}[*] Killing process $pid...${NC}"
    kill $pid 2>/dev/null || kill -9 $pid 2>/dev/null
    sleep 1

    echo -e "${GREEN}[+] Restarting through MITM proxy...${NC}"
    echo ""

    # Restart through proxy
    if [ -n "$args" ]; then
        intercept_program "$exe_path" $args
    else
        intercept_program "$exe_path"
    fi
}

select_tool() {
    # Validate and select the tool
    case "$MITM_TOOL" in
        mitmproxy|mitmweb|mitmdump)
            if ! command -v "$MITM_TOOL" &> /dev/null; then
                echo -e "${RED}[-] $MITM_TOOL not found${NC}"
                echo -e "${YELLOW}[*] Install with: sudo pacman -S mitmproxy${NC}"
                exit 1
            fi
            echo -e "${GREEN}[+] Using tool: $MITM_TOOL${NC}"
            ;;
        *)
            echo -e "${RED}[-] Invalid tool: $MITM_TOOL${NC}"
            echo -e "${YELLOW}[*] Valid options: mitmproxy, mitmweb, mitmdump${NC}"
            exit 1
            ;;
    esac
}

reset_proxy() {
    echo -e "${YELLOW}[!] This will:${NC}"
    echo "    - Kill all running mitmproxy processes"
    echo "    - Remove mitmproxy configuration and certificates"
    echo "    - Remove system-wide CA certificate installation"
    echo "    - Clean up all logs and saved flows"
    echo "    - Restore iptables rules"
    echo ""
    read -p "Are you sure? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[*] Cancelled${NC}"
        exit 0
    fi

    echo -e "${GREEN}[+] Resetting proxy and SSL certificates...${NC}"

    # Kill all mitmproxy processes
    echo -e "${YELLOW}[*] Killing all mitmproxy processes...${NC}"
    pkill -f mitmproxy 2>/dev/null || true
    pkill -f mitmweb 2>/dev/null || true
    pkill -f mitmdump 2>/dev/null || true
    sleep 1

    # Remove iptables rules if running as root
    if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}[*] Cleaning up iptables rules...${NC}"
        sudo iptables -t nat -D OUTPUT -j MITM 2>/dev/null || true
        sudo iptables -t nat -F MITM 2>/dev/null || true
        sudo iptables -t nat -X MITM 2>/dev/null || true

        if [ -f /tmp/iptables.backup ]; then
            sudo iptables-restore < /tmp/iptables.backup 2>/dev/null || true
            sudo rm /tmp/iptables.backup
        fi
    fi

    # Remove system CA certificate
    echo -e "${YELLOW}[*] Removing system CA certificate...${NC}"
    if [ -f /etc/ca-certificates/trust-source/anchors/mitmproxy.crt ]; then
        sudo rm /etc/ca-certificates/trust-source/anchors/mitmproxy.crt 2>/dev/null || true
        sudo trust extract-compat 2>/dev/null || true
        echo -e "${GREEN}[+] Removed from Arch Linux trust store${NC}"
    fi
    if [ -f /usr/local/share/ca-certificates/mitmproxy.crt ]; then
        sudo rm /usr/local/share/ca-certificates/mitmproxy.crt 2>/dev/null || true
        sudo update-ca-certificates 2>/dev/null || true
        echo -e "${GREEN}[+] Removed from Debian/Ubuntu trust store${NC}"
    fi

    # Remove mitmproxy directory
    echo -e "${YELLOW}[*] Removing mitmproxy configuration and certificates...${NC}"
    if [ -d "$MITMPROXY_DIR" ]; then
        rm -rf "$MITMPROXY_DIR"
        echo -e "${GREEN}[+] Removed $MITMPROXY_DIR${NC}"
    fi

    # Remove logs
    echo -e "${YELLOW}[*] Removing logs and saved flows...${NC}"
    if [ -d "$MITM_LOG_DIR" ]; then
        rm -rf "$MITM_LOG_DIR"
        echo -e "${GREEN}[+] Removed $MITM_LOG_DIR${NC}"
    fi

    echo -e "${GREEN}[+] Reset complete!${NC}"
    echo -e "${YELLOW}[*] Note: You may need to manually remove certificates from browsers${NC}"
}

setup_mitmproxy() {
    echo -e "${GREEN}[+] Starting mitmproxy...${NC}"

    # Generate certificates if not exists
    if [ ! -f "$MITMPROXY_DIR/mitmproxy-ca-cert.pem" ]; then
        echo -e "${YELLOW}[*] Generating mitmproxy certificates...${NC}"
        mitmdump --set confdir="$MITMPROXY_DIR" -p $PROXY_PORT &
        local pid=$!
        sleep 3
        kill $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
    fi
}

install_certificate() {
    setup_mitmproxy

    echo -e "${GREEN}[+] Installing mitmproxy CA certificate...${NC}"

    local cert_file="$MITMPROXY_DIR/mitmproxy-ca-cert.pem"

    if [ ! -f "$cert_file" ]; then
        echo -e "${RED}[-] Certificate not found. Run the proxy first.${NC}"
        exit 1
    fi

    # Install for system
    if [ -d /etc/ca-certificates/trust-source/anchors ]; then
        # Arch Linux
        sudo cp "$cert_file" /etc/ca-certificates/trust-source/anchors/mitmproxy.crt
        sudo trust extract-compat
        echo -e "${GREEN}[+] Certificate installed system-wide (Arch Linux)${NC}"
    elif [ -d /usr/local/share/ca-certificates ]; then
        # Debian/Ubuntu
        sudo cp "$cert_file" /usr/local/share/ca-certificates/mitmproxy.crt
        sudo update-ca-certificates
        echo -e "${GREEN}[+] Certificate installed system-wide (Debian/Ubuntu)${NC}"
    fi

    # Install for browsers
    echo -e "${YELLOW}[*] For Firefox:${NC}"
    echo "    1. Open Firefox preferences -> Privacy & Security -> Certificates"
    echo "    2. Click 'View Certificates' -> 'Authorities' -> 'Import'"
    echo "    3. Import: $cert_file"
    echo ""
    echo -e "${YELLOW}[*] For Chrome/Chromium:${NC}"
    echo "    1. Open chrome://settings/certificates"
    echo "    2. Click 'Authorities' -> 'Import'"
    echo "    3. Import: $cert_file"
    echo ""
    echo -e "${GREEN}[+] Certificate location: $cert_file${NC}"
}

intercept_program() {
    local cmd=("$@")

    if [ ${#cmd[@]} -eq 0 ]; then
        echo -e "${RED}[-] No command specified${NC}"
        print_usage
        exit 1
    fi

    setup_mitmproxy

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$MITM_LOG_DIR/program_${timestamp}.log"
    local flow_file="$MITM_LOG_DIR/program_${timestamp}.mitm"

    echo -e "${GREEN}[+] Starting $MITM_TOOL on port $PROXY_PORT...${NC}"
    echo -e "${YELLOW}[*] Logs will be saved to: $log_file${NC}"
    echo -e "${YELLOW}[*] Flows will be saved to: $flow_file${NC}"
    echo ""

    # Start the selected tool in background
    if [ "$MITM_TOOL" = "mitmproxy" ]; then
        # For mitmproxy, run in foreground terminal mode
        $MITM_TOOL --set confdir="$MITMPROXY_DIR" \
                --mode regular \
                --listen-port $PROXY_PORT \
                --ssl-insecure \
                --set flow_detail=3 \
                --save-stream-file "$flow_file" \
                > "$log_file" 2>&1 &
    else
        # For mitmweb and mitmdump, run in background
        $MITM_TOOL --set confdir="$MITMPROXY_DIR" \
                --mode regular \
                --listen-port $PROXY_PORT \
                --ssl-insecure \
                --set flow_detail=3 \
                --save-stream-file "$flow_file" \
                > "$log_file" 2>&1 &
    fi

    local mitm_pid=$!

    # Wait for proxy to start
    echo -e "${YELLOW}[*] Waiting for proxy to start...${NC}"
    sleep 3

    # Check if mitmproxy started successfully
    if ! kill -0 $mitm_pid 2>/dev/null; then
        echo -e "${RED}[-] Failed to start $MITM_TOOL${NC}"
        cat "$log_file"
        exit 1
    fi

    echo -e "${GREEN}[+] $MITM_TOOL started (PID: $mitm_pid)${NC}"
    if [ "$MITM_TOOL" = "mitmweb" ]; then
        echo -e "${GREEN}[+] Web interface: http://127.0.0.1:8081${NC}"
    fi
    echo -e "${YELLOW}[*] Running command: ${cmd[*]}${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Set up cleanup trap
    trap "echo ''; echo -e '${YELLOW}[*] Stopping $MITM_TOOL...${NC}'; kill $mitm_pid 2>/dev/null || true; wait $mitm_pid 2>/dev/null || true; echo -e '${GREEN}[+] Logs saved to: $log_file${NC}'; echo -e '${GREEN}[+] Flows saved to: $flow_file${NC}'; echo -e '${YELLOW}[*] View flows with: mitmproxy -r $flow_file${NC}'" EXIT INT TERM

    # Run the command with proxy settings
    env \
        http_proxy="http://127.0.0.1:$PROXY_PORT" \
        https_proxy="http://127.0.0.1:$PROXY_PORT" \
        HTTP_PROXY="http://127.0.0.1:$PROXY_PORT" \
        HTTPS_PROXY="http://127.0.0.1:$PROXY_PORT" \
        REQUESTS_CA_BUNDLE="$MITMPROXY_DIR/mitmproxy-ca-cert.pem" \
        SSL_CERT_FILE="$MITMPROXY_DIR/mitmproxy-ca-cert.pem" \
        NODE_EXTRA_CA_CERTS="$MITMPROXY_DIR/mitmproxy-ca-cert.pem" \
        "${cmd[@]}"
}

intercept_system() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[-] System-wide interception requires root privileges${NC}"
        echo -e "${YELLOW}[*] Run with: sudo $0 system${NC}"
        exit 1
    fi

    setup_mitmproxy

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$MITM_LOG_DIR/system_${timestamp}.log"
    local flow_file="$MITM_LOG_DIR/system_${timestamp}.mitm"

    echo -e "${GREEN}[+] Starting system-wide traffic interception...${NC}"
    echo -e "${YELLOW}[*] Logs will be saved to: $log_file${NC}"
    echo -e "${YELLOW}[*] Flows will be saved to: $flow_file${NC}"
    echo ""

    # Start the selected tool in transparent mode
    echo -e "${GREEN}[+] Starting $MITM_TOOL in transparent mode...${NC}"

    sudo -u $SUDO_USER $MITM_TOOL --set confdir="$MITMPROXY_DIR" \
            --mode transparent \
            --listen-port $PROXY_PORT \
            --ssl-insecure \
            --set flow_detail=3 \
            --save-stream-file "$flow_file" \
            --showhost \
            > "$log_file" 2>&1 &

    local mitm_pid=$!

    # Wait for proxy to start
    echo -e "${YELLOW}[*] Waiting for proxy to start...${NC}"
    sleep 3

    # Check if mitmproxy started successfully
    if ! kill -0 $mitm_pid 2>/dev/null; then
        echo -e "${RED}[-] Failed to start $MITM_TOOL${NC}"
        cat "$log_file"
        exit 1
    fi

    echo -e "${GREEN}[+] $MITM_TOOL started (PID: $mitm_pid)${NC}"
    if [ "$MITM_TOOL" = "mitmweb" ]; then
        echo -e "${GREEN}[+] Web interface: http://127.0.0.1:8081${NC}"
    fi

    # Set up iptables rules
    echo -e "${GREEN}[+] Setting up iptables rules...${NC}"

    # Save current iptables rules
    iptables-save > /tmp/iptables.backup

    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null

    # Create new chain for MITM
    iptables -t nat -N MITM 2>/dev/null || iptables -t nat -F MITM

    # Ignore traffic to/from proxy
    iptables -t nat -A MITM -d 127.0.0.1 -j RETURN
    iptables -t nat -A MITM -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A MITM -d 10.0.0.0/8 -j RETURN

    # Redirect HTTP traffic
    iptables -t nat -A MITM -p tcp --dport 80 -j REDIRECT --to-port $PROXY_PORT

    # Redirect HTTPS traffic
    iptables -t nat -A MITM -p tcp --dport 443 -j REDIRECT --to-port $PROXY_PORT

    # Apply the chain to output
    iptables -t nat -A OUTPUT -j MITM

    echo -e "${GREEN}[+] Iptables rules configured${NC}"
    echo ""
    echo -e "${YELLOW}[*] All system traffic is now being intercepted${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop...${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"

    # Set up cleanup trap
    trap "echo ''; echo -e '${YELLOW}[*] Stopping system-wide interception...${NC}'; stop_system_intercept $mitm_pid; echo -e '${GREEN}[+] Logs saved to: $log_file${NC}'; echo -e '${GREEN}[+] Flows saved to: $flow_file${NC}'; echo -e '${YELLOW}[*] View flows with: mitmproxy -r $flow_file${NC}'" EXIT INT TERM

    # Wait for mitmproxy
    wait $mitm_pid
}

stop_system_intercept() {
    local mitm_pid=$1

    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[-] Stopping system-wide interception requires root privileges${NC}"
        echo -e "${YELLOW}[*] Run with: sudo $0 stop${NC}"
        exit 1
    fi

    echo -e "${GREEN}[+] Removing iptables rules...${NC}"

    # Remove MITM chain from OUTPUT
    iptables -t nat -D OUTPUT -j MITM 2>/dev/null || true

    # Flush and delete MITM chain
    iptables -t nat -F MITM 2>/dev/null || true
    iptables -t nat -X MITM 2>/dev/null || true

    # Restore iptables if backup exists
    if [ -f /tmp/iptables.backup ]; then
        echo -e "${YELLOW}[*] Restoring original iptables rules...${NC}"
        iptables-restore < /tmp/iptables.backup
        rm /tmp/iptables.backup
    fi

    # Kill mitmproxy if PID provided
    if [ -n "$mitm_pid" ] && kill -0 $mitm_pid 2>/dev/null; then
        echo -e "${YELLOW}[*] Stopping mitmproxy (PID: $mitm_pid)...${NC}"
        kill $mitm_pid 2>/dev/null || true
        wait $mitm_pid 2>/dev/null || true
    else
        # Try to find and kill any running mitmproxy instances
        pkill -f "mitmweb.*--mode transparent" 2>/dev/null || true
    fi

    echo -e "${GREEN}[+] System-wide interception stopped${NC}"
}

# Main script
print_banner

if [ $# -eq 0 ]; then
    print_usage
    exit 1
fi

case "$1" in
    reset)
        # Reset doesn't need requirements or tool selection
        reset_proxy
        exit 0
        ;;
    -p|-r)
        # Fuzzy find needs fzf
        check_requirements true
        ;;
    *)
        # All other commands need requirements check
        check_requirements
        ;;
esac

case "$1" in
    -p)
        select_tool
        shift
        intercept_fuzzy_program "$@"
        ;;
    -r)
        select_tool
        shift
        intercept_running_process "$@"
        ;;
    program)
        select_tool
        shift
        intercept_program "$@"
        ;;
    system)
        select_tool
        intercept_system
        ;;
    install-cert)
        install_certificate
        ;;
    stop)
        stop_system_intercept ""
        ;;
    *)
        echo -e "${RED}[-] Unknown command: $1${NC}"
        print_usage
        exit 1
        ;;
esac
