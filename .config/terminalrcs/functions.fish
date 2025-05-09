# FZF default options
set --export FZF_DEFAULT_OPTS '--cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="*"'

# Bring background job to foreground via fzf
# Usage: fzfjobs
# Lets you select a background job using fzf and brings it to the foreground
function fzfjobs
    set selected_pid (jobs | fzf --prompt="Select job: " | awk '{print $2}')
    and fg %$selected_pid
end

# Insert selected files at command line
# Usage: fzffiles
# Uses fd to find files recursively and fzf to select them, then inserts the selection at the current command line position
function fzffiles
    set cmd (commandline)
    set selected_files (fd --type f -d 100 -H | fzf --multi --prompt="Select files: " --preview "bat --style=numbers --color=always {}" 2>/dev/null)
    if test -n "$selected_files"
        commandline -r "$cmd $selected_files"
    end
end

# Grep and insert matched file
# Usage: fzfgrep
# Searches for text in files recursively using ripgrep, allows selection with fzf, and inserts the file path at cursor
function fzfgrep
    set cmd (commandline)
    set match (
        rg --hidden --line-number --no-heading --color=always . -d 100 2>/dev/null \
        | fzf --ansi --prompt="Grep file: " \
              --delimiter=: \
              --preview='bat --style=numbers --color=always {1} --highlight-line {2}' \
              --preview-window=up:70%
    )

    if test -n "$match"
        set file (echo $match | cut -d: -f1)
        commandline -r "$cmd $file"
    end
end
# File selector with preview
# Usage: fzfall
# Browses files in the current directory with preview using fzf and inserts the selected file at cursor
function fzfall
    set cmd (commandline)
    set selected_file (fzf --prompt="Select file: " --preview "bat --style=numbers --color=always {}" --preview-window=right:60%)
    if test -n "$selected_file"
        commandline -r "$cmd $selected_file"
    end
end

# Show which package owns a command
# Usage: whoown command_name
# Identifies which package installed a command using pacman
function whoown
    set cmd (command -v $argv[1] 2>/dev/null)
    if test -n "$cmd"
        pacman -Qo $cmd
    else
        echo "Command not found: $argv[1]" >&2
    end
end

# Grep and open in Neovim
# Usage: fzfnvim
# Searches for text in files recursively using ripgrep, lets you select results with fzf, and opens the file at the matching line in Neovim
function fzfnvim
    set match (
        rg --hidden --line-number --no-heading --color=always . -d 100 2>/dev/null \
        | fzf --ansi --prompt="Grep & open in Neovim: " \
              --delimiter=: \
              --preview='bat --style=numbers --color=always {1} --highlight-line {2}' \
              --preview-window=up:70%
    )

    if test -n "$match"
        set file (echo $match | cut -d: -f1)
        set line (echo $match | cut -d: -f2)
        if test -n "$file" -a -n "$line"
            nvim +"$line" "$file"
        end
    end
end

# Extract 7z archives to their own directories
# Usage: 7zx archive.7z
# Creates a directory named after the archive and extracts contents into it
function 7zx
    set filename (basename $argv[1])
    set dirname (string replace -r '\.[^.]*$' '' $filename)
    mkdir -p $dirname
    7z x $argv[1] -o$dirname
end
# Interactive package search and install with paru
# Usage: fzfparu
# Searches available packages with paru, provides detailed preview with fzf, and installs selected packages
function fzfparu
    paru -Slq | fzf -m --preview 'paru -Si {1}; echo ""; echo "Files:"; paru -Fl {1} | awk "{print \$2}"' | xargs -ro paru -S
end
