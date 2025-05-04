export FZF_DEFAULT_OPTS='--preview "bat --color=always {}"'                                                                                             # Set default options for fzf with bat preview
alias ls='eza -al --color=always --group-directories-first --icons'                                                                                     # preferred listing - list all files with details
alias la='eza -a --color=always --group-directories-first --icons'                                                                                      # all files and dirs - list all files including hidden
alias ll='eza -l --color=always --group-directories-first --icons'                                                                                      # long format - detailed list view
alias lt='eza -aT --color=always --group-directories-first --icons'                                                                                     # tree listing - display files in tree structure
alias l.="eza -a | grep -e '^\.'"                                                                                                                       # show only dotfiles - list only hidden files
alias cat="bat"                                                                                                                                         # replace cat with bat for syntax highlighting
alias find="fd"                                                                                                                                         # replace find with fd for better performance
alias mirror="sudo cachyos-rate-mirrors"                                                                                                                # update mirrors to fastest ones using cachyos tool
alias plz='sudo -E -s'                                                                                                                                  # run command with sudo while preserving environment vars
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'                                                                                                         # remove packages that are no longer needed
alias jctl="journalctl -p 3 -xb"                                                                                                                        # show error messages from system logs
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"                                                                           # list recently installed packages
alias cp="cp -iv"                                                                                                                                       # verbose and interactive copy
alias mv="mv -iv"                                                                                                                                       # verbose and interactive move
alias rm="rm -vI"                                                                                                                                       # verbose and safer remove (asks once when removing multiple files)
alias cls="clear"                                                                                                                                       # clear terminal screen
alias home="cd ~"                                                                                                                                       # go to home directory
alias df="df -ahiT --total"                                                                                                                             # enhanced disk usage display
alias mkdir="mkdir -pv"                                                                                                                                 # create parent directories as needed, verbose
alias mkfile="touch"                                                                                                                                    # create empty file
alias userlist="cut -d: -f1 /etc/passwd"                                                                                                                # list all users on system
alias free="free -mt"                                                                                                                                   # show memory usage with total
alias duach="du -ach | sort -h"                                                                                                                         # disk usage sorted by size with human-readable format
alias ps="ps auxf"                                                                                                                                      # list all processes with details
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"                                                                                                # search processes
alias wget="wget -c"                                                                                                                                    # continue downloading if interrupted
alias th="history | fzf |wl-copy "                                                                                                                      # fuzzy search command history and copy to clipboard
alias myip="curl http://ipecho.net/plain; echo"                                                                                                         # display public IP address
alias folders='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'                                                                         # list folders by size
alias grep='grep --color=auto'                                                                                                                          # colorize grep output
alias cope="gh copilot"                                                                                                                                 # shortcut for GitHub Copilot
alias ch="cliphist list | fzf | cliphist decode | wl-copy"                                                                                              # fuzzy search clipboard history
alias paru="paru --color=always"                                                                                                                        # colorized paru output
alias v="nvim"                                                                                                                                          # shortcut for neovim
alias paruedit="paru --fm nvim -Sy"                                                                                                                     # update and edit with neovim
alias yay="paru"                                                                                                                                        # use paru as yay replacement
alias pacmirrors="reflector --verbose -c Brazil --latest 10 --sort rate --save /etc/pacman.d/mirrorlist  && pacman -Sy && pacman -Qe > ~/installed.txt" # update mirrors sorted by rate
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"                                                                                                # update grub config
alias fixpacman="sudo rm /var/lib/pacman/db.lck"                                                                                                        # remove pacman lock file
alias tarnow='tar -acf '                                                                                                                                # create compressed archive
alias untar='tar -zxvf '                                                                                                                                # extract tar archive
alias psmem='ps auxf | sort -nr -k 4'                                                                                                                   # list processes by memory usage
alias psmem10='ps auxf | sort -nr -k 4 | head -10'                                                                                                      # top 10 processes by memory usage
alias ..='cd ..'                                                                                                                                        # go up one directory
alias ...='cd ../..'                                                                                                                                    # go up two directories
alias ....='cd ../../..'                                                                                                                                # go up three directories
alias .....='cd ../../../..'                                                                                                                            # go up four directories
alias ......='cd ../../../../..'                                                                                                                        # go up five directories
alias dir='dir --color=auto'                                                                                                                            # colorized directory listing
alias vdir='vdir --color=auto'                                                                                                                          # colorized verbose directory listing
alias fgrep='fgrep --color=auto'                                                                                                                        # colorized fixed string grep
alias egrep='egrep --color=auto'                                                                                                                        # colorized extended grep
alias hw='hwinfo --short'                                                                                                                               # hardware info in short format
alias big="expac -H M '%m\t%n' | sort -h | nl"                                                                                                          # sort installed packages by size
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'                                                                                                      # count git packages installed
alias update='sudo pacman -Syu'                                                                                                                         # update system packages
alias chx='chmod +x *'                                                                                                                                  # make all files in current dir executable
alias cdz='z $(fzf)'                                                                                                                                    # fuzzy search directories with z
alias zf='fd --type f | fzf --preview "bat --color=always {}"'                                                                                          # fuzzy search files with preview
alias gpp='g++ -g -Wall -Wextra -gdwarf-4'                                                                                                              # g++ with debugging flags
alias n='$HOME/scripts/notfiy.sh'                                                                                                                       # run notification script
alias q='exit'                                                                                                                                          # quick exit
alias lssizes='du -h | sort -h'                                                                                                                         # list files/dirs by size
alias lssize='du -achd1 | sort -h'                                                                                                                      # list first-level dirs by size
alias ports='ss -tulanp'                                                                                                                                # show all open ports
alias cpu='cat /proc/cpuinfo | grep "model name" | head -1'                                                                                             # show CPU info
alias diskspace='df -h | grep -v tmp'                                                                                                                   # show disk space usage
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'                                          # run internet speed test
alias download='aria2c -x 16 -s 16'                                                                                                                     # download with high speed using aria2
alias copy='xclip -selection clipboard'                                                                                                                 # copy to clipboard
alias paste='xclip -selection clipboard -o'                                                                                                             # paste from clipboard
alias diffy='diff -y --suppress-common-lines'                                                                                                           # side-by-side diff showing only changes
alias extip='curl -s ifconfig.me'                                                                                                                       # get external IP address
alias dmesg='dmesg -T'                                                                                                                                  # human readable timestamps in dmesg
alias batt='upower -i $(upower -e | grep BAT) | grep percentage'                                                                                        # show battery percentage
alias wifi='nmcli device wifi list'                                                                                                                     # list available wifi networks
alias less='less -R'                                                                                                                                    # show ANSI colors properly
alias back='cd "$OLDPWD"'                                                                                                                               # go back to previous directory
alias cpv='rsync -ah --info=progress2'                                                                                                                  # copy with progress bar
alias webserver='python -m http.server 8000'                                                                                                            # start a simple web server
alias watch='watch -n1 -d'                                                                                                                              # watch with 1s updates and highlighting
