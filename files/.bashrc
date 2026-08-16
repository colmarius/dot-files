
export HISTSIZE=1000000

bind "set show-all-if-ambiguous On"

. ~/.zsh/aliases
. ~/.zsh/git-aliases
. ~/.zsh/npm-completion
. ~/.zsh/nvm
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
