set -g fish_greeting


if type -q starship
    starship init fish | source
    set -gx STARSHIP_CACHE $XDG_CACHE_HOME/starship
    set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml
end


if type -q duf
    function df -d "Run duf with last argument if valid, else run duf"
        if set -q argv[-1] && test -e $argv[-1]
            duf $argv[-1]
        else
            duf
        end
    end
end

# fzf



# NOTE: binds Alt+n to inserting the nth command from history in edit buffer
# e.g. Alt+4 is same as pressing Up arrow key 4 times
# really helpful if you get used to it
bind_M_n_history



# example integration with bat : <cltr+f>
# bind -M insert \ce '$EDITOR $(fzf --preview="bat --color=always --plain {}")'


set fish_pager_color_prefix cyan
set fish_color_autosuggestion brblack

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
    
