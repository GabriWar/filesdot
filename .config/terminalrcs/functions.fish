function fzfjobs
    set selected_pid (jobs | fzf | awk '{print $2}')
    and fg %$selected_pid
end

function fzffiles
    set cmd (commandline)
    set selected_files (fd --type f -d 6 -H | fzf --multi --prompt="Select files: " --preview "bat --color=always {}")
    if test -n "$selected_files"
        set -l files (echo $selected_files | tr '\n' ' ')
        eval $cmd $files
    else
        echo "No files selected."
    end
end

function fzfgrep
    set file (fd -t f -d 6 -H | xargs grep -n . | fzf --ansi | awk -F: '{print $1}')
    if test -n "$file"
        commandline -t "$file"
    end
end

function fzfall
    set selected_file (fzf --prompt="Select file: " --preview "bat --color=always {}" --preview-window=right:60%)
    if test -n "$selected_file"
        commandline -t "$selected_file"
    else
        echo "No file selected."
    end
end
