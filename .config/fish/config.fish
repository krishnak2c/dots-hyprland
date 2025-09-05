function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

starship init fish | source
if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
end

alias pamcan pacman
alias ls 'eza --icons'
alias clear "printf '\033[2J\033[3J\033[1;1H'"
alias q 'qs -c ii'
    

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end
# List Directory
alias c='clear'
alias l='eza -lh --icons=auto'
alias ls='eza -1 --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias un='sudo $aurhelper -Rns $argv'
alias up='sudo $aurhelper -Syu $argv'
alias pl='$aurhelper -Qs'
alias pa='sudo $aurhelper -S $argv'
alias pc='$aurhelper -Sc'
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'
alias vc='codium'
alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc \
          --logo-type kitty --logo "$(ls "$LOGO_DIR"/*.icon | shuf -n 1)"'

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# Add Flutter to PATH
set -gx PATH $PATH /home/krishna/flutter/bin
    
alias update='sudo pacman -Syu && yay -Syu --devel'

fish_add_path /home/krishna/.spicetify
