#!/bin/bash

# Force bash execution - re-exec with bash if not running in bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Process Tracer - Trace file access of running processes
# Uses lsof and strace with optional fzf for better UX

set -euo pipefail

# --- Colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

# --- Utility Functions ---
error() {
	echo -e "${RED}Error: $1${NC}" >&2
	exit 1
}

info() {
	echo -e "${BLUE}ℹ${NC} $1"
}

success() {
	echo -e "${GREEN}✓${NC} $1"
}

warn() {
	echo -e "${YELLOW}⚠${NC} $1"
}

check_dependency() {
	local cmd="$1"
	local optional="${2:-false}"

	if ! command -v "$cmd" &>/dev/null; then
		if [ "$optional" = "true" ]; then
			return 1
		else
			error "'$cmd' is not installed. Please install it first."
		fi
	fi
	return 0
}

check_root_for_strace() {
	if [ "$EUID" -ne 0 ] && [ -z "${SUDO_USER:-}" ]; then
		warn "strace often requires root privileges to attach to processes."
		info "You may need to run this script with sudo."
		read -p "Continue anyway? (y/N): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			exit 0
		fi
	fi
}

# --- Check Dependencies ---
check_dependency "lsof"
check_dependency "strace"
HAS_FZF=$(check_dependency "fzf" true && echo "true" || echo "false")

# --- Process Selection ---
select_process_with_fzf_loop() {
	local filter="$1"

	# Build ps command
	local ps_cmd="ps aux"
	if [ -n "$filter" ]; then
		ps_cmd="ps aux | grep -i '$filter' | grep -v grep | grep -v $0"
	fi

	# Create preview script
	local preview_script='
PID=$(echo {} | awk "{print \$2}")

# Header
echo -e "\033[1;36m╔══════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║             Process Details (PID: $PID)                 ║\033[0m"
echo -e "\033[1;36m╚══════════════════════════════════════════════════════════╝\033[0m"
echo

# Basic Info
echo -e "\033[1;33m▶ PROCESS INFO\033[0m"
ps -p $PID -o pid,ppid,user,%cpu,%mem,stat,start,time,command 2>/dev/null | tail -n +2 || echo "Process not found"
echo

# Working Directory
echo -e "\033[1;33m▶ WORKING DIRECTORY\033[0m"
pwdx $PID 2>/dev/null | sed "s/^$PID: //" || echo "N/A"
echo

# Open Files with lsof
echo -e "\033[1;33m▶ OPEN FILES (lsof)\033[0m"
echo -e "\033[0;90mShowing all file descriptors and memory-mapped files...\033[0m"
echo

lsof_output=$(lsof -p $PID 2>/dev/null)
if [ -n "$lsof_output" ]; then
    file_count=$(echo "$lsof_output" | tail -n +2 | wc -l)
    echo -e "\033[1;32m✓ Total open files: $file_count\033[0m"
    echo
    echo "$lsof_output" | head -n 1
    echo "$lsof_output" | tail -n +2 | head -n 30
    
    if [ "$file_count" -gt 30 ]; then
        remaining=$((file_count - 30))
        echo -e "\033[0;90m... and $remaining more files (press F1 for full view)\033[0m"
    fi
else
    echo -e "\033[0;31m✗ No files found or permission denied\033[0m"
fi
echo

# Recent system calls with strace (quick sample)
echo -e "\033[1;33m▶ RECENT FILE OPERATIONS (strace sample)\033[0m"
echo -e "\033[0;90mSampling 2 seconds of file operations...\033[0m"
echo

strace_output=$(timeout 2 strace -p $PID -e trace=open,openat,openat2,read,write,stat,lstat -q 2>&1 || true)
if echo "$strace_output" | grep -q "Operation not permitted"; then
    echo -e "\033[0;31m✗ Permission denied (try running with sudo)\033[0m"
elif [ -n "$strace_output" ]; then
    echo "$strace_output" | grep -E "^(open|read|write|stat)" | tail -n 15
    echo -e "\033[0;90m(Press F2 to run full live strace)\033[0m"
else
    echo -e "\033[0;90mNo recent file operations detected in sample\033[0m"
fi
echo
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;33mQuick Actions:\033[0m F1=lsof | F2=strace | F3=process tree"
echo -e "\033[1;33mNavigation:\033[0m Enter=Full menu | ESC=Exit | Ctrl+R=Refresh"
'

	# Run fzf with bash-wrapped execute bindings
	local selected
	selected=$(eval "$ps_cmd" | tail -n +2 |
		fzf --ansi \
			--header="📋 Select Process | F1:lsof F2:strace F3:tree | Enter:Menu ESC:Exit" \
			--header-first \
			--prompt="🔍 Process> " \
			--pointer="▶" \
			--preview="bash -c '$preview_script'" \
			--preview-window='down:70%:wrap:border-top' \
			--bind='ctrl-r:reload(ps aux | tail -n +2)' \
			--bind='ctrl-/:toggle-preview' \
			--bind='f1:execute(bash -c '\''
                PID=$(echo {} | awk "{print \$2}");
                clear;
                echo -e "\033[1;36m╔════════════════════════════════════════════════════════╗\033[0m";
                echo -e "\033[1;36m║         lsof - All Open Files (PID: $PID)            ║\033[0m";
                echo -e "\033[1;36m╚════════════════════════════════════════════════════════╝\033[0m";
                echo;
                lsof -p $PID 2>/dev/null | less -R +G || echo "Error running lsof";
                echo;
                echo -e "\033[1;33mPress Enter to continue...\033[0m";
                read
            '\'')' \
			--bind='f2:execute(bash -c '\''
                PID=$(echo {} | awk "{print \$2}");
                CMD=$(ps -p $PID -o comm= 2>/dev/null);
                clear;
                echo -e "\033[1;36m╔════════════════════════════════════════════════════════╗\033[0m";
                echo -e "\033[1;36m║      strace - Live Trace for $CMD (PID: $PID)        ║\033[0m";
                echo -e "\033[1;36m╚════════════════════════════════════════════════════════╝\033[0m";
                echo -e "\033[1;33mPress Ctrl+C to stop tracing\033[0m";
                echo;
                sleep 1;
                sudo strace -p $PID -e trace=open,openat,openat2,read,write,close,stat,lstat,access -f 2>&1 || strace -p $PID -e trace=open,openat,openat2,read,write,close,stat,lstat,access -f 2>&1 || echo "Error: Permission denied";
                echo;
                echo -e "\033[1;33mPress Enter to continue...\033[0m";
                read
            '\'')' \
			--bind='f3:execute(bash -c '\''
                PID=$(echo {} | awk "{print \$2}");
                clear;
                echo -e "\033[1;36m╔════════════════════════════════════════════════════════╗\033[0m";
                echo -e "\033[1;36m║           Process Tree (PID: $PID)                    ║\033[0m";
                echo -e "\033[1;36m╚════════════════════════════════════════════════════════╝\033[0m";
                echo;
                pstree -p -a -s $PID 2>/dev/null || ps -p $PID -o pid,ppid,cmd;
                echo;
                echo -e "\033[1;33mPress Enter to continue...\033[0m";
                read
            '\'')' \
			--info=inline)

	if [ -z "$selected" ]; then
		echo "exit"
		return
	fi

	echo "$selected" | awk '{print $2}'
}

# --- Main Menu ---
show_main_menu() {
	local pid="$1"
	local cmd="$2"
	
	clear
	echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
	echo -e "${BOLD}${CYAN}║                    Process Tracer Menu                      ║${NC}"
	echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
	echo
	echo -e "${BOLD}Process:${NC} $cmd (PID: $pid)"
	echo
	echo -e "${GREEN}1.${NC} Show all open files (lsof)"
	echo -e "${GREEN}2.${NC} Live file operations trace (strace)"
	echo -e "${GREEN}3.${NC} Process tree"
	echo -e "${GREEN}4.${NC} Process details"
	echo -e "${GREEN}5.${NC} Select different process"
	echo -e "${RED}6.${NC} Exit"
	echo
	read -p "Choose option [1-6]: " choice
	echo "$choice"
}

# --- Main Functions ---
trace_process_files() {
	local pid="$1"
	
	info "Tracing file operations for PID $pid..."
	echo -e "${YELLOW}Press Ctrl+C to stop tracing${NC}"
	echo
	
	sudo strace -p "$pid" -e trace=open,openat,openat2,read,write,close,stat,lstat,access -f 2>&1 || \
	strace -p "$pid" -e trace=open,openat,openat2,read,write,close,stat,lstat,access -f 2>&1 || \
	error "Permission denied. Try running with sudo."
}

show_open_files() {
	local pid="$1"
	
	info "Showing open files for PID $pid..."
	echo
	
	lsof -p "$pid" 2>/dev/null | less -R +G || error "Error running lsof or permission denied"
}

show_process_tree() {
	local pid="$1"
	
	info "Showing process tree for PID $pid..."
	echo
	
	pstree -p -a -s "$pid" 2>/dev/null || ps -p "$pid" -o pid,ppid,cmd || error "Process not found"
}

show_process_details() {
	local pid="$1"
	
	info "Process details for PID $pid:"
	echo
	
	# Basic process info
	ps -p "$pid" -o pid,ppid,user,%cpu,%mem,stat,start,time,command 2>/dev/null || error "Process not found"
	echo
	
	# Working directory
	echo -e "${BOLD}Working Directory:${NC}"
	pwdx "$pid" 2>/dev/null | sed "s/^$pid: //" || echo "N/A"
	echo
	
	# Memory usage
	echo -e "${BOLD}Memory Usage:${NC}"
	ps -p "$pid" -o pid,vsz,rss,pmem,comm 2>/dev/null || echo "N/A"
}

# --- Main Script ---
main() {
	local filter="${1:-}"
	local pid=""
	local cmd=""
	
	# Check if fzf is available
	if [ "$HAS_FZF" = "true" ]; then
		info "Using fzf for process selection..."
		pid=$(select_process_with_fzf_loop "$filter")
		
		if [ "$pid" = "exit" ]; then
			info "Exiting..."
			exit 0
		fi
		
		cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "Unknown")
	else
		# Fallback to simple selection
		info "fzf not available, using simple process selection..."
		echo
		ps aux | head -1
		ps aux | tail -n +2 | head -20
		echo
		read -p "Enter PID to trace: " pid
		
		if [ -z "$pid" ] || ! ps -p "$pid" >/dev/null 2>&1; then
			error "Invalid PID: $pid"
		fi
		
		cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "Unknown")
	fi
	
	# Main loop
	while true; do
		choice=$(show_main_menu "$pid" "$cmd")
		
		case "$choice" in
			1)
				show_open_files "$pid"
				read -p "Press Enter to continue..."
				;;
			2)
				trace_process_files "$pid"
				read -p "Press Enter to continue..."
				;;
			3)
				show_process_tree "$pid"
				read -p "Press Enter to continue..."
				;;
			4)
				show_process_details "$pid"
				read -p "Press Enter to continue..."
				;;
			5)
				# Select new process
				if [ "$HAS_FZF" = "true" ]; then
					pid=$(select_process_with_fzf_loop "$filter")
					if [ "$pid" = "exit" ]; then
						info "Exiting..."
						exit 0
					fi
				else
					read -p "Enter new PID: " pid
					if [ -z "$pid" ] || ! ps -p "$pid" >/dev/null 2>&1; then
						error "Invalid PID: $pid"
					fi
				fi
				cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "Unknown")
				;;
			6)
				info "Exiting..."
				exit 0
				;;
			*)
				warn "Invalid option. Please choose 1-6."
				sleep 1
				;;
		esac
	done
}

# --- Script Entry Point ---
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	check_root_for_strace
	main "$@"
fi
