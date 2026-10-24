# The following lines were added by Docker Desktop to add commands to your PATH.
if [ -d "$HOME/.docker/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.docker/bin:"*) ;;
        *) export PATH="$PATH:$HOME/.docker/bin" ;;
    esac
fi
# End of Docker Desktop section.

[ -f ~/.bashrc ] && . ~/.bashrc
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
