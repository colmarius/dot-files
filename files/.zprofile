# The following lines were added by Docker Desktop to add commands to your PATH.
if [ -d "$HOME/.docker/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.docker/bin:"*) ;;
        *) export PATH="$PATH:$HOME/.docker/bin" ;;
    esac
fi
# End of Docker Desktop section.

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
