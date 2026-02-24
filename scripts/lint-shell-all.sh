#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is required. Install it with: brew install shellcheck" >&2
  exit 1
fi

shell_files=(
  "clone_and_link.sh"
  "files/.bash_profile"
  "files/.bashrc"
  "files/.zprofile"
  "files/.zshrc"
  "files/.zsh/aliases"
  "files/.zsh/bindkeys"
  "files/.zsh/completion"
  "files/.zsh/direnv"
  "files/.zsh/ghostty"
  "files/.zsh/git-aliases"
  "files/.zsh/google-cloud"
  "files/.zsh/java"
  "files/.zsh/npm-completion"
  "files/.zsh/nvm"
  "files/.zsh/nvm-autoload"
  "files/.zsh/options"
  "files/.zsh/prompt"
  "files/.zsh/python"
  "files/.zsh/rc"
  "files/.zsh/ruby"
  "files/.zsh/ssh"
)

existing_files=()
for file in "${shell_files[@]}"; do
  if [ -f "$file" ]; then
    existing_files+=("$file")
  fi
done

if [ "${#existing_files[@]}" -eq 0 ]; then
  echo "No shell files configured for linting"
  exit 0
fi

echo "Running full advisory shell lint on ${#existing_files[@]} files"
echo "Note: zsh-specific constructs may trigger bash-oriented ShellCheck warnings"

set +e
shellcheck --shell=bash "${existing_files[@]}"
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "Advisory shell lint passed"
  exit 0
fi

echo
echo "Advisory shell lint reported issues"
echo "Set STRICT=1 to make this command fail (STRICT=1 bash scripts/lint-shell-all.sh)"

if [ "${STRICT:-0}" = "1" ]; then
  exit "$status"
fi

exit 0
