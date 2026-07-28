
# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _correct _approximate
zstyle :compinstall filename '/home/avi/.zshrc'

fpath=(~/.zsh/completions $fpath)

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

# fnm
FNM_PATH="/home/avi/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

eval "$(fnm env --use-on-cd --shell zsh)"

# bun completions
[ -s "/home/avi/.bun/_bun" ] && source "/home/avi/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
