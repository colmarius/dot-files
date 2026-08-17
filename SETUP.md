## Setup new tools

Recommend using [Ghostty] as the terminal on macOS.

Libraries needed to install when setting up on a new computer:

After installing [brew] simply run:

    brew install direnv
    brew install selecta
    brew install diff-so-fancy
    brew install ripgrep
    brew install shellcheck
    brew install ffmpeg
    brew install nvm
    brew install pyenv
    brew install chruby
    brew install ruby-install
    brew install openjdk@25

Install the versions pinned by this checkout:

    mkdir -p "$HOME/.nvm"
    . "$(brew --prefix nvm)/nvm.sh"
    nvm install "$(cat files/.nvmrc)"
    ruby-install ruby "$(cat files/.ruby-version)"
    pyenv install "$(cat files/.python-version)"

Terminal tools:

- [brew]: package manager for macOS (or Linux)
- [direnv]: unclutter your .profile
- [selecta]: a fuzzy text selector for files and anything else you need to select
- [diff-so-fancy]: good-lookin' diffs
- [ripgrep]: recursively searches directories for a regex pattern while respecting your gitignore
- [shellcheck]: static analysis for shell scripts
- [semgrep]: lightweight static analysis for many languages

Media tools

- [ffmpeg]: record, convert, and stream audio and video

Web development

- [nvm]: Node Version Manager
- [pyenv]: Python Version Manager
- [chruby]: Ruby Version Manager
- [biome]: Biome is a fast formatter for JavaScript, TypeScript, JSX, TSX

Cloud serverless development

- [gcloud]: Cloud SDK
- [firebase-tools]: Firebase Tools

Agent workflow

- The checked-in [dot-agents] workflow requires standard `bash`, `curl`, and `tar` tools.
- Refresh it from the repository root with `.agents/scripts/sync.sh --force`.

Pi setup

- Install the Pi coding agent:

      npm install -g @mariozechner/pi-coding-agent

- After running `clone_and_link.sh` once, store the OpenAI API key in macOS Keychain and configure Pi auth:

      bash scripts/setup-pi-openai-key.sh set

  The script only manages the `openai` entry in `~/.pi/agent/auth.json` and preserves any other provider entries already stored there.

  Remove the stored Pi OpenAI key and auth entry:

      bash scripts/setup-pi-openai-key.sh unset

- Global Pi settings are managed in `files/.pi/agent/settings.json` and linked to `~/.pi/agent/settings.json` by `clone_and_link.sh` without replacing the rest of `~/.pi` or overwriting `~/.pi/agent/auth.json`.

- If a previous broken `clone_and_link.sh` run removed `~/.pi/agent/auth.json`, recreate it with:

      bash scripts/setup-pi-openai-key.sh set

  If the script reports a legacy `~/.pi` symlink, run `bash clone_and_link.sh` first so it can repair `~/.pi` before writing Pi auth.

[Ghostty]: https://ghostty.org/download
[brew]: https://brew.sh
[direnv]: https://direnv.net
[selecta]: https://github.com/garybernhardt/selecta
[diff-so-fancy]: https://github.com/so-fancy/diff-so-fancy
[ripgrep]: https://github.com/BurntSushi/ripgrep
[shellcheck]: https://www.shellcheck.net
[ffmpeg]: https://ffmpeg.org/
[nvm]: https://github.com/nvm-sh/nvm#install--update-script
[pyenv]: https://github.com/pyenv/pyenv
[chruby]: https://github.com/postmodern/chruby
[gcloud]: https://cloud.google.com/sdk/docs/install
[firebase-tools]: https://firebase.google.com/docs/cli#mac-linux-npm
[semgrep]: https://github.com/semgrep/semgrep
[biome]: https://biomejs.dev/guides/manual-installation
[dot-agents]: https://dot-agents.dev/
