
export HISTSIZE=1000000

bind "set show-all-if-ambiguous On"

. ~/.zsh/aliases
. ~/.zsh/git-aliases
. ~/.zsh/npm-completion
. ~/.zsh/nvm
# Select the nearest .nvmrc (or default), even when the parent inherited older Node.
if type nvm >/dev/null 2>&1; then
  if [ -n "$(nvm_find_nvmrc)" ]; then
    nvm use --silent >/dev/null
  else
    nvm use --silent default >/dev/null
  fi
fi
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
