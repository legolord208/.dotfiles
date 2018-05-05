# BASED ON grml-zsh-config because it had all the things I wanted by default.

# --------------------------------
# General
# --------------------------------

eval "$(dircolors ~/.dircolors)"

alias clear='clear; echo -ne "\e[3J"'
alias git=hub
alias ls="ls -CF --color=auto"
alias nix-shell="nix-shell --run zsh"
alias rsynca='rsync -avzhP'

unicopy() {
    [ -z "$1" ] && echo "unicopy <character>" && return
    unicode "$1" --format "{pchar}" | xclip -sel clip
}
loop() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "loop <n> <command...>"
        return
    fi

    for _ in $(seq 1 "$1"); do
        eval "${@:2}"
    done
}
powerline() {
    PS1="$(powerline-rs --shell zsh $?)"
}
precmd_functions+=(powerline)

# https://github.com/pstadler/keybase-gpg-github/issues/11
export GPG_TTY="$(tty)"

# --------------------------------
# Options
# --------------------------------

setopt HIST_IGNORE_DUPS

# --------------------------------
# Plugins
# --------------------------------

# Plugins are loaded using NixOS's things.
# I'm using:
# - autojump
# - grml-zsh-config
# - zsh-autosuggestions
# - zsh-completions
# - zsh-syntax-highlighting

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="bg=10"

# --------------------------------
# System updates
# --------------------------------

if [ ! -f "/tmp/pacman-updates" ]; then
    checkupdates > /tmp/pacman-updates
fi
if [ ! -f "/tmp/aur-updates" ]; then
    trizen -Syua 2> /dev/null > /tmp/aur-updates
fi

updates="$(cat /tmp/pacman-updates | wc -l)"
if [ "$updates" -gt 0 ]; then
    echo "\rSystem update: $updates packages available."
    echo "sudo pacman -Syu"
    rm /tmp/pacman-updates # If they upgrade, don't display the outdated version
fi
updates="$(cat /tmp/aur-updates | wc -l)"
if [ "$updates" -gt 0 ]; then
    echo "\rSystem update: $updates packages available *from the AUR*."
    echo "trizen -Syua"
    rm /tmp/aur-updates # If they upgrade, don't display the outdated version
fi
