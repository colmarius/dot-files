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

# >>> amoled_companion ESP-IDF environment >>>
if [[ -z "${IDF_PATH:-}" \
    && -x "$PWD/.tools/python-current/bin/python3" \
    && -f "$PWD/.tools/esp-idf/export.sh" \
    && -f "$PWD/main/idf_component.yml" ]] \
    && grep -Fq 'project(amoled_companion)' "$PWD/CMakeLists.txt" 2>/dev/null; then
    export PATH="$PWD/.tools/python-current/bin:$PATH"
    export IDF_TOOLS_PATH="$PWD/.tools/espressif"
    # shellcheck disable=SC1091
    . "$PWD/.tools/esp-idf/export.sh" >/dev/null
fi
# <<< amoled_companion ESP-IDF environment <<<
