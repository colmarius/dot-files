## Setup new tools

Recommend to use [iterm2] as Mac terminal.

Libraries needed to install when setting up on a new computer:

After installing [brew] simply run:

    brew install direnv
    brew install selecta
    brew install diff-so-fancy
    brew install ripgrep
    brew install shellcheck
    brew install nvm
    brew install pyenv
    brew install chruby
    brew install ruby-install

    ruby-install # see version
    pyenv install # see version

Terminal tools:

- [brew]: package manager for macOS (or Linux)
- [direnv]: unclutter your .profile
- [selecta]: a fuzzy text selector for files and anything else you need to select
- [diff-so-fancy]: good-lookin' diffs
- [ripgrep]: recursively searches directories for a regex pattern while respecting your gitignore
- [shellcheck]: static analysis for shell scripts
- [semgrep]: lightweight static analysis for many languages

Web development

- [nvm]: Node Version Manager
- [pyenv]: Python Version Manager
- [chruby]: Ruby Version Manager
- [biome]: Biome is a fast formatter for JavaScript, TypeScript, JSX, TSX

Cloud severless development

- [gcloud]: Cloud SDK
- [firebase-tools]: Firebase Tools

Pi setup

- Install the Pi coding agent:

      npm install -g @mariozechner/pi-coding-agent

- Store the OpenAI API key in macOS Keychain and configure Pi auth:

      bash scripts/setup-pi-openai-key.sh set

  Remove the stored Pi OpenAI key and auth entry:

      bash scripts/setup-pi-openai-key.sh unset

- Global Pi settings are managed in `files/.pi/agent/settings.json` and linked to `~/.pi/agent/settings.json` by `clone_and_link.sh` without replacing the rest of `~/.pi`.

[ghostty]: https://ghostty.org/download
[brew]: https://brew.sh
[direnv]: https://direnv.net
[selecta]: https://github.com/garybernhardt/selecta
[diff-so-fancy]: https://github.com/so-fancy/diff-so-fancy
[ripgrep]: https://github.com/BurntSushi/ripgrep
[shellcheck]: https://www.shellcheck.net
[nvm]: https://github.com/nvm-sh/nvm#install--update-script
[pyenv]: https://github.com/pyenv/pyenv
[chruby]: https://github.com/postmodern/chruby
[gcloud]: https://cloud.google.com/sdk/docs/install
[firebase-tools]: https://firebase.google.com/docs/cli#mac-linux-npm
[semgrep]: https://github.com/semgrep/semgrep
[biome]: https://biomejs.dev/guides/manual-installation
