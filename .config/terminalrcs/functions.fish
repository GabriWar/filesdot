# FZF default options
set --export FZF_DEFAULT_OPTS '--cycle --layout=reverse --border --height=90% --preview-window=wrap --marker="*"'

# Bring background job to foreground via fzf
function fzfjobs
    set selected_pid (jobs | fzf --prompt="Select job: " | awk '{print $2}')
    and fg %$selected_pid
end

# Insert selected files at command line
function fzffiles
    set cmd (commandline)
    set selected_files (fd --type f -d 100 -H | fzf --multi --prompt="Select files: " --preview "bat --style=numbers --color=always {}" 2>/dev/null)
    if test -n "$selected_files"
        commandline -r "$cmd $selected_files"
    end
end

# Grep and insert matched file

function fzfgrep
    set cmd (commandline)
    set match (
        rg --line-number --no-heading --color=always . 2>/dev/null \
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
function fzfall
    set cmd (commandline)
    set selected_file (fzf --prompt="Select file: " --preview "bat --style=numbers --color=always {}" --preview-window=right:60%)
    if test -n "$selected_file"
        commandline -r "$cmd $selected_file"
    end
end

# Show which package owns a command
function whoown
    set cmd (command -v $argv[1] 2>/dev/null)
    if test -n "$cmd"
        pacman -Qo $cmd
    else
        echo "Command not found: $argv[1]" >&2
    end
end

function fzfnvim
    set match (
        rg --line-number --no-heading --color=always . 2>/dev/null \
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

function 7zx
    set filename (basename $argv[1])
    set dirname (string replace -r '\.[^.]*$' '' $filename)
    mkdir -p $dirname
    7z x $argv[1] -o$dirname
end
