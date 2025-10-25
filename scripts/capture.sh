#!/bin/bash

# Universal System-Wide Proxy Capture Script
# Works with Fiddler, Burp Suite, and other proxy tools
# Uses iptables transparent redirect with GID-based loop prevention
# Can also launch proxy tools with noproxy group to prevent redirect loops

NOPROXY_GID=$(getent group noproxy | cut -d: -f3)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Proxy tool configurations
declare -A PROXY_PORTS=(
    ["fiddler"]=8866
    ["burp"]=8080
    ["burpsuite"]=8080
    ["mitmproxy"]=8080
    ["zaproxy"]=8080
    ["zap"]=8080
)

detect_proxy() {
    echo -e "${BLUE}Detecting running proxy tools...${NC}"

    # Check Fiddler
    if pgrep -f "Fiddler.WebUi" > /dev/null; then
        echo -e "${GREEN}✓ Fiddler detected (port 8866)${NC}"
        return 0
    fi

    # Check Burp Suite
    if pgrep -f "burp" > /dev/null || ss -tlnp 2>/dev/null | grep -q ":8080.*java"; then
        echo -e "${GREEN}✓ Burp Suite detected (port 8080)${NC}"
        return 0
    fi

    # Check mitmproxy
    if pgrep -f "mitmproxy" > /dev/null; then
        echo -e "${GREEN}✓ mitmproxy detected (port 8080)${NC}"
        return 0
    fi

    # Check ZAP
    if pgrep -f "zap" > /dev/null; then
        echo -e "${GREEN}✓ ZAP detected (port 8080)${NC}"
        return 0
    fi

    echo -e "${YELLOW}⚠ No proxy tool detected${NC}"
    return 1
}

check_status() {
    if sudo iptables -t nat -L OUTPUT -n 2>/dev/null | grep -q "redir ports"; then
        return 0  # Enabled
    else
        return 1  # Disabled
    fi
}

enable_capture() {
    local PROXY_PORT=$1
    local TOOL_NAME=$2

    # Validate port
    if [ -z "$PROXY_PORT" ]; then
        echo -e "${RED}ERROR: Proxy port not specified${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Enabling system-wide capture...${NC}"
    echo -e "  Target: ${BLUE}$TOOL_NAME${NC} on port ${BLUE}$PROXY_PORT${NC}"

    # Check if proxy is listening
    if ! ss -tlnp 2>/dev/null | grep -q ":$PROXY_PORT"; then
        echo -e "${YELLOW}⚠ Warning: Nothing is listening on port $PROXY_PORT${NC}"
        echo -e "  Make sure $TOOL_NAME is running first!"
    fi

    # Check noproxy group exists
    if [ -z "$NOPROXY_GID" ]; then
        echo -e "${RED}ERROR: noproxy group does not exist${NC}"
        echo -e "Run: sudo groupadd noproxy && sudo usermod -a -G noproxy \$USER"
        exit 1
    fi

    # Don't redirect localhost traffic (prevents loops)
    sudo iptables -t nat -I OUTPUT -p tcp -d 127.0.0.0/8 -j RETURN

    # Don't redirect traffic from noproxy group (proxy tool runs with this GID)
    sudo iptables -t nat -I OUTPUT -p tcp -m owner --gid-owner $NOPROXY_GID -j RETURN

    # Redirect HTTP (port 80) to proxy
    sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -m owner ! --uid-owner root -j REDIRECT --to-ports $PROXY_PORT

    # Redirect HTTPS (port 443) to proxy
    sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -m owner ! --uid-owner root -j REDIRECT --to-ports $PROXY_PORT

    echo -e "${GREEN}✓ System-wide capture ENABLED${NC}"
    echo -e "  All HTTP/HTTPS traffic is being redirected to port $PROXY_PORT"
    echo -e ""
    echo -e "${YELLOW}IMPORTANT:${NC}"
    echo -e "  • $TOOL_NAME must run with GID noproxy: ${BLUE}sg noproxy -c 'your-tool'${NC}"
    echo -e "  • Set Gateway/Upstream proxy to: ${BLUE}No proxy / Direct${NC}"
    echo -e "  • Restart GUI apps (Firefox, Chrome, etc.) to capture their traffic"
}

disable_capture() {
    echo -e "${YELLOW}Disabling system-wide capture...${NC}"

    # Flush all redirect rules
    sudo iptables -t nat -F OUTPUT 2>/dev/null

    echo -e "${GREEN}✓ System-wide capture DISABLED${NC}"
    echo -e "  Traffic is now flowing normally"
}

show_status() {
    if check_status; then
        echo -e "${GREEN}Status: ENABLED${NC}"
        echo ""
        echo -e "${BLUE}Current iptables NAT rules:${NC}"
        sudo iptables -t nat -L OUTPUT -n -v --line-numbers | grep -E "(Chain OUTPUT|REDIRECT|RETURN|policy)" | sed 's/^/  /'
        echo ""
        echo -e "${BLUE}Active redirects:${NC}"
        sudo iptables -t nat -L OUTPUT -n | grep "REDIRECT" | awk '{print "  → Port " $NF " redirecting"}' || echo "  None"
    else
        echo -e "${RED}Status: DISABLED${NC}"
    fi

    echo ""
    echo -e "${BLUE}Listening proxy tools:${NC}"
    ss -tlnp 2>/dev/null | grep -E ":(8080|8866|8888)" | awk '{print "  " $4 " - " $6}' || echo "  None detected"
}

launch_burp() {
    local BURP_PATH="$1"
    
    if [ -z "$BURP_PATH" ]; then
        echo -e "${YELLOW}Searching for Burp Suite in common locations...${NC}"
        
        # Common Burp Suite locations
        BURP_LOCATIONS=(
            "$HOME/BurpSuitePro/BurpSuitePro"
            "$HOME/.BurpSuite/burpsuite_pro.jar"
            "/opt/burpsuite/burpsuite_pro.jar"
            "/usr/bin/burpsuite"
            "$HOME/Downloads/burpsuite_pro.jar"
        )
        
        # Find Burp Suite
        for location in "${BURP_LOCATIONS[@]}"; do
            if [ -f "$location" ]; then
                BURP_PATH="$location"
                break
            fi
        done
        
        if [ -z "$BURP_PATH" ]; then
            echo -e "${RED}ERROR: Burp Suite not found in common locations${NC}"
            echo -e "Please specify the path manually: ${BLUE}capture -b /path/to/burp${NC}"
            echo ""
            echo -e "${YELLOW}Searching for burp files...${NC}"
            find ~ -name "*burp*.jar" 2>/dev/null | head -5
            exit 1
        fi
    fi
    
    if [ ! -f "$BURP_PATH" ]; then
        echo -e "${RED}ERROR: Burp Suite not found at: $BURP_PATH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Starting Burp Suite with noproxy group...${NC}"
    echo -e "Path: ${BLUE}$BURP_PATH${NC}"
    
    # Run Burp Suite with noproxy group
    if [[ "$BURP_PATH" == *.jar ]]; then
        sg noproxy -c "java -jar '$BURP_PATH'"
    else
        sg noproxy -c "'$BURP_PATH'"
    fi
}

launch_fiddler() {
    local FIDDLER_PATH="$1"
    
    if [ -z "$FIDDLER_PATH" ]; then
        echo -e "${YELLOW}Searching for Fiddler in common locations...${NC}"
        
        # Common Fiddler locations
        FIDDLER_LOCATIONS=(
            "./fiddler-everywhere"
            "$HOME/fiddler-everywhere"
            "/opt/fiddler-everywhere"
            "/usr/bin/fiddler-everywhere"
        )
        
        # Find Fiddler
        for location in "${FIDDLER_LOCATIONS[@]}"; do
            if [ -f "$location" ]; then
                FIDDLER_PATH="$location"
                break
            fi
        done
        
        if [ -z "$FIDDLER_PATH" ]; then
            echo -e "${RED}ERROR: Fiddler not found in common locations${NC}"
            echo -e "Please specify the path manually: ${BLUE}capture -f /path/to/fiddler${NC}"
            exit 1
        fi
    fi
    
    if [ ! -f "$FIDDLER_PATH" ]; then
        echo -e "${RED}ERROR: Fiddler not found at: $FIDDLER_PATH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Starting Fiddler with noproxy group...${NC}"
    echo -e "Path: ${BLUE}$FIDDLER_PATH${NC}"
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Run Fiddler with noproxy group
    sg noproxy -c "cd '$SCRIPT_DIR' && '$FIDDLER_PATH'"
}

find_free_port() {
    local port=8080
    while ss -tlnp 2>/dev/null | grep -q ":$port "; do
        ((port++))
    done
    echo $port
}

launch_mitmproxy() {
    local MITMPROXY_MODE="$1"
    local CUSTOM_ARGS="$2"
    
    # If no mode specified, default to mitmweb
    if [ -z "$MITMPROXY_MODE" ]; then
        MITMPROXY_MODE="mitmweb"
    fi
    
    # If no custom args specified, find a free port and use it
    if [ -z "$CUSTOM_ARGS" ]; then
        local FREE_PORT=$(find_free_port)
        MITMPROXY_ARGS="--listen-port $FREE_PORT"
        echo -e "${YELLOW}Using port $FREE_PORT (8080 was busy)${NC}"
    else
        MITMPROXY_ARGS="$CUSTOM_ARGS"
    fi
    
    # Check if the specified mode is available in PATH
    if command -v "$MITMPROXY_MODE" >/dev/null 2>&1; then
        MITMPROXY_PATH="$MITMPROXY_MODE"
    else
        echo -e "${YELLOW}Searching for mitmproxy in common locations...${NC}"
        
        # Common mitmproxy locations for the specified mode
        MITMPROXY_LOCATIONS=(
            "$HOME/.local/bin/$MITMPROXY_MODE"
            "/usr/local/bin/$MITMPROXY_MODE"
            "/usr/bin/$MITMPROXY_MODE"
        )
        
        # Find the specified mitmproxy mode
        for location in "${MITMPROXY_LOCATIONS[@]}"; do
            if [ -f "$location" ]; then
                MITMPROXY_PATH="$location"
                break
            fi
        done
        
        if [ -z "$MITMPROXY_PATH" ]; then
            echo -e "${RED}ERROR: $MITMPROXY_MODE not found${NC}"
            echo -e "Please install mitmproxy: ${BLUE}pip install mitmproxy${NC}"
            echo -e "Or specify the path manually: ${BLUE}capture -m /path/to/$MITMPROXY_MODE${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}Starting $MITMPROXY_MODE with noproxy group...${NC}"
    echo -e "Command: ${BLUE}$MITMPROXY_PATH $MITMPROXY_ARGS${NC}"
    echo ""
    
    # Run mitmproxy with noproxy group
    if [[ "$MITMPROXY_PATH" == "mitmproxy" || "$MITMPROXY_PATH" == "mitmweb" || "$MITMPROXY_PATH" == "mitmdump" ]]; then
        sg noproxy -c "$MITMPROXY_PATH $MITMPROXY_ARGS"
    else
        sg noproxy -c "'$MITMPROXY_PATH' $MITMPROXY_ARGS"
    fi
}

enable_capture_on_port() {
    local PROXY_PORT="$1"
    
    # Validate port number
    if ! [[ "$PROXY_PORT" =~ ^[0-9]+$ ]] || [ "$PROXY_PORT" -lt 1 ] || [ "$PROXY_PORT" -gt 65535 ]; then
        echo -e "${RED}ERROR: Invalid port number '$PROXY_PORT'${NC}"
        echo -e "Port must be a number between 1 and 65535"
        exit 1
    fi
    
    if check_status; then
        echo -e "${YELLOW}Capture is already enabled${NC}"
        echo -e "Disable current capture first: ${BLUE}./capture.sh off${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Enabling system-wide capture on port $PROXY_PORT...${NC}"
    
    # Check if proxy is listening on the specified port
    if ! ss -tlnp 2>/dev/null | grep -q ":$PROXY_PORT "; then
        echo -e "${YELLOW}⚠ Warning: Nothing is listening on port $PROXY_PORT${NC}"
        echo -e "  Make sure your proxy tool is running on port $PROXY_PORT first!"
    else
        echo -e "${GREEN}✓ Proxy detected on port $PROXY_PORT${NC}"
    fi
    
    # Check noproxy group exists
    if [ -z "$NOPROXY_GID" ]; then
        echo -e "${RED}ERROR: noproxy group does not exist${NC}"
        echo -e "Run: sudo groupadd noproxy && sudo usermod -a -G noproxy \$USER"
        exit 1
    fi
    
    # Don't redirect localhost traffic (prevents loops)
    sudo iptables -t nat -I OUTPUT -p tcp -d 127.0.0.0/8 -j RETURN
    
    # Don't redirect traffic from noproxy group (proxy tool runs with this GID)
    sudo iptables -t nat -I OUTPUT -p tcp -m owner --gid-owner $NOPROXY_GID -j RETURN
    
    # Redirect HTTP (port 80) to proxy
    sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -m owner ! --uid-owner root -j REDIRECT --to-ports $PROXY_PORT
    
    # Redirect HTTPS (port 443) to proxy
    sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -m owner ! --uid-owner root -j REDIRECT --to-ports $PROXY_PORT
    
    echo -e "${GREEN}✓ System-wide capture ENABLED on port $PROXY_PORT${NC}"
    echo -e "  All HTTP/HTTPS traffic is being redirected to port $PROXY_PORT"
    echo ""
    echo -e "${YELLOW}🔧 IMPORTANT REMINDERS:${NC}"
    echo -e "  • Your proxy tool must run with GID noproxy: ${BLUE}sg noproxy -c 'your-proxy-tool'${NC}"
    echo -e "  • Set Gateway/Upstream proxy to: ${BLUE}No proxy / Direct${NC}"
    echo -e "  • Restart GUI apps (Firefox, Chrome, etc.) to capture their traffic"
    echo -e "  • To disable: ${BLUE}./capture.sh off${NC}"
}

launch_mitmproxy_invisible() {
    local MITMPROXY_ARGS="--mode transparent --listen-port 8080"
    
    echo -e "${GREEN}Starting mitmproxy in invisible transparent mode with noproxy group...${NC}"
    echo -e "Command: ${BLUE}mitmproxy $MITMPROXY_ARGS${NC}"
    echo ""
    echo -e "${YELLOW}🔧 INVISIBLE TRANSPARENT PROXY:${NC}"
    echo -e "  • Running in ${BLUE}transparent mode${NC} (no proxy config needed)"
    echo -e "  • Traffic is intercepted transparently via iptables"
    echo -e "  • Tool is running with ${BLUE}noproxy group${NC} (no redirect loops)"
    echo -e "  • To capture traffic: ${BLUE}./capture.sh on mitmproxy${NC}"
    echo -e "  • No browser proxy configuration needed!"
    echo ""
    
    if command -v mitmproxy >/dev/null 2>&1; then
        sg noproxy -c "mitmproxy $MITMPROXY_ARGS"
    else
        echo -e "${RED}ERROR: mitmproxy not found${NC}"
        echo -e "Please install mitmproxy: ${BLUE}pip install mitmproxy${NC}"
        exit 1
    fi
}

# Main script logic
case "$1" in
    -b|--burp)
        launch_burp "$2"
        ;;
    
    -f|--fiddler)
        launch_fiddler "$2"
        ;;
    
    -m|--mitmproxy)
        launch_mitmproxy "$2"
        ;;
    
    -mi|--mitmproxy-invisible)
        launch_mitmproxy_invisible
        ;;
    
    -p|--port)
        enable_capture_on_port "$2"
        ;;
    
    on|enable|start)
        if check_status; then
            echo -e "${YELLOW}Capture is already enabled${NC}"
            show_status
            exit 0
        fi

        # Determine tool and port
        TOOL="${2:-auto}"

        if [ "$TOOL" = "auto" ]; then
            # Auto-detect
            if pgrep -f "Fiddler.WebUi" > /dev/null; then
                PROXY_PORT=8866
                TOOL_NAME="Fiddler"
            elif pgrep -f "burp" > /dev/null || ss -tlnp 2>/dev/null | grep -q ":8080.*java"; then
                PROXY_PORT=8080
                TOOL_NAME="Burp Suite"
            elif ss -tlnp 2>/dev/null | grep -q ":8080"; then
                PROXY_PORT=8080
                TOOL_NAME="Proxy"
            elif ss -tlnp 2>/dev/null | grep -q ":8866"; then
                PROXY_PORT=8866
                TOOL_NAME="Proxy"
            else
                echo -e "${RED}ERROR: No proxy tool detected${NC}"
                echo -e "Specify manually: $0 on <fiddler|burp|PORT>"
                detect_proxy
                exit 1
            fi
        elif [[ "$TOOL" =~ ^[0-9]+$ ]]; then
            # Port number provided
            PROXY_PORT=$TOOL
            TOOL_NAME="Proxy"
        else
            # Tool name provided
            TOOL_LOWER=$(echo "$TOOL" | tr '[:upper:]' '[:lower:]')
            if [ -n "${PROXY_PORTS[$TOOL_LOWER]}" ]; then
                PROXY_PORT=${PROXY_PORTS[$TOOL_LOWER]}
                TOOL_NAME="$TOOL"
            else
                echo -e "${RED}ERROR: Unknown tool '$TOOL'${NC}"
                echo -e "Supported: fiddler, burp, burpsuite, mitmproxy, zap, zaproxy"
                echo -e "Or specify a port number directly"
                exit 1
            fi
        fi

        enable_capture $PROXY_PORT "$TOOL_NAME"
        ;;

    off|disable|stop)
        if ! check_status; then
            echo -e "${YELLOW}Capture is already disabled${NC}"
            exit 0
        fi
        disable_capture
        ;;

    status)
        show_status
        ;;

    toggle|"")
        if check_status; then
            disable_capture
        else
            # Try to auto-enable
            $0 on auto
        fi
        ;;

    detect)
        detect_proxy
        ;;

    *)
        echo "Usage: $0 {on|off|toggle|status|detect|-b|-f|-m|-mi|-p} [tool|port|path]"
        echo ""
        echo "Commands:"
        echo "  on [tool|port]     - Enable capture (auto-detects if not specified)"
        echo "                        Examples: on fiddler, on burp, on mitmproxy, on 8080, on (auto)"
        echo "  off                - Disable capture"
        echo "  toggle             - Toggle capture on/off"
        echo "  status             - Show current status and iptables rules"
        echo "  detect             - Detect running proxy tools"
        echo ""
        echo "Launch tools:"
        echo "  -b [path]          - Launch Burp Suite with noproxy group"
        echo "  -f [path]          - Launch Fiddler with noproxy group"
        echo "  -m [mode]          - Launch mitmproxy with noproxy group"
        echo "                        Modes: mitmproxy (terminal), mitmweb (web), mitmdump (dump)"
        echo "                        Auto-finds free port if 8080 is busy"
        echo "  -mi                - Launch mitmproxy in invisible transparent mode"
        echo "                        No browser proxy config needed, uses iptables"
        echo "  -p PORT              - Enable capture on specific port"
        echo "                        Works with any proxy tool you launch manually"
        echo ""
        echo "Supported tools:"
        echo "  fiddler (8866), burp/burpsuite (8080), mitmproxy (8080)"
        echo "  zap/zaproxy (8080), or any custom port number"
        echo ""
        echo "Examples:"
        echo "  $0 on                 # Auto-detect and enable capture"
        echo "  $0 on fiddler         # Enable for Fiddler"
        echo "  $0 on burp            # Enable for Burp Suite"
        echo "  $0 on mitmproxy       # Enable for mitmproxy"
        echo "  $0 on 9090            # Enable for custom port"
        echo "  $0 off                # Disable capture"
        echo "  $0 status             # Show status"
        echo "  $0 -b                 # Launch Burp Suite (auto-detect path)"
        echo "  $0 -b /path/to/burp   # Launch Burp Suite from specific path"
        echo "  $0 -f                 # Launch Fiddler (auto-detect path)"
        echo "  $0 -f /path/to/fiddler # Launch Fiddler from specific path"
        echo "  $0 -m                 # Launch mitmproxy (web interface)"
        echo "  $0 -m mitmproxy       # Launch mitmproxy (terminal interface)"
        echo "  $0 -m mitmweb         # Launch mitmproxy (web interface)"
        echo "  $0 -m mitmdump        # Launch mitmproxy (dump mode)"
        echo "  $0 -mi                # Launch mitmproxy (invisible transparent mode)"
        echo "  $0 -p 8080            # Enable capture on port 8080 (any proxy tool)"
        echo "  $0 -p 9090            # Enable capture on port 9090 (any proxy tool)"
        echo "  $0 -p 8866            # Enable capture on port 8866 (any proxy tool)"
        exit 1
        ;;
esac

exit 0
