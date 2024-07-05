function fzfjobs
    set selected_pid (jobs | fzf | awk '{print $2}')
    and fg %$selected_pid
end

function fzffiles
    set cmd (commandline)
    set selected_files (fd --type f -d 10 -H | fzf --multi --prompt="Select files: " --preview "bat --color=always {}")
    if test -n "$selected_files"
        set -l files (echo $selected_files | tr '\n' ' ')
        commandline -r "$cmd $files"
    end
end

function fzfgrep
    set cmd (commandline)
    set file (fd -t f -d 10 -H | xargs grep -n -I . | fzf --ansi | awk -F: '{print $1}')
    if test -n "$file"
        commandline -r "$cmd $file"
    end
end

function fzfall
    set cmd (commandline)
    set selected_file (fzf --prompt="Select file: " --preview "bat --color=always {}" --preview-window=right:60%)
    if test -n "$selected_file"
        commandline -r "$cmd $selected_file"
    end
end
