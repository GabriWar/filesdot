# Replace ls with eza cat with bat and find with fd
export FZF_DEFAULT_OPTS='--preview "bat --color=always {}"'
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'"                                   # show only dotfiles
alias cat="bat"
alias find="fd"
# Get fastest mirrors on cachy
alias mirror="sudo cachyos-rate-mirrors"
# sudo keeping the environment variables
alias plz='sudo -E -s'
# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"
# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
# Verbosity and settings that you pretty much just always are going to want.
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -vI"
### bunch of useful aliasses
#############
alias cls="clear"
alias home="cd ~"
alias df="df -ahiT --total"
alias mkdir="mkdir -pv"
alias mkfile="touch"
alias rm="rm -rfi"
alias userlist="cut -d: -f1 /etc/passwd"
alias free="free -mt"
alias du="du -ach | sort -h"
alias ps="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias wget="wget -c"
alias th="history | fzf |wl-copy "
alias myip="curl http://ipecho.net/plain; echo"
alias folders='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias grep='grep --color=auto'
alias cope="gh copilot"
alias wallp="sh ~/.config/hypr/scripts/randomwall.sh &"
alias ch= "cliphist list | fzf | cliphist decode | wl-copy"
alias paru="paru --color=always"
alias v="nvim"
alias paruedit="paru --fm nvim -Sy"
alias yay="paru"
alias pacmirrors="reflector --verbose -c Brazil --latest 10 --sort rate --save /etc/pacman.d/mirrorlist  && pacman -Sy && pacman -Qe > ~/installed.txt",
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias hw='hwinfo --short'                          # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl"     # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
alias update='sudo pacman -Syu'
alias chx='chmod +x *'
alias cdz='z $(fzf)'
alias zf='fd --type f | fzf --preview "bat --color=always {}"'
alias gpp='g++ -g -Wall -Wextra -gdwarf-4'
alias n='$HOME/scripts/notfiy.sh'
alias q='exit'
