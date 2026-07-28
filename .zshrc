
# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _correct _approximate
zstyle :compinstall filename '/home/avi/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=5000
setopt autocd extendedglob notify
bindkey -e
# End of lines configured by zsh-newuser-install

export PATH="/home/avi/.local/bin:$PATH"

eval "$(sheldon source)"
eval "$(starship init zsh)"
