function fzfg
    set selected_pid (jobs | fzf | awk '{print $2}')
    and fg %$selected_pid
end
