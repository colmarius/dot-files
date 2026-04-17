My _dot files_ configuration. After using a forked version for a while I decided to customize my own version.

## Setup

Before reusing this configuration please change:

- [files/.gitconfig](files/.gitconfig)
- [clone_and_link.sh](clone_and_link.sh)

## Usage

    bash <(curl -fsS https://raw.githubusercontent.com/colmarius/dot-files/main/clone_and_link.sh)

Lint shell files locally:

    bash scripts/lint-shell.sh

Run a broader advisory lint (includes `files/.zsh/*` and does not fail by default):

    bash scripts/lint-shell-all.sh

Run npm run completion regression checks:

    bash scripts/test-npm-run-local-completion.sh

Pi OpenAI key setup lives in [SETUP.md](SETUP.md).

Pi global settings are tracked in [files/.pi/agent/settings.json](files/.pi/agent/settings.json) and linked to `~/.pi/agent/settings.json` by `clone_and_link.sh` without taking over the rest of `~/.pi`.

Temporarily disable the local `npm run` completion override:

    export NPM_RUN_LOCAL_COMPLETION_DISABLE=1

Optionally, follow steps in [SETUP.md](SETUP.md)

## Credits

Heavily inspired by:

- [benhoskings/dot-files](https://github.com/benhoskings/dot-files)

## Resources

- [Dotfiles should be forked](http://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/)
- [Github dotfiles](https://dotfiles.github.io/)
