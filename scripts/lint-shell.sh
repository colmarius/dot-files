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
  "scripts/setup-pi-openai-key.sh"
  "scripts/test-clone-and-link-pi.sh"
  "scripts/test-npm-run-local-completion.sh"
  "scripts/test-shell-regressions.sh"
  "scripts/test-setup-pi-openai-key.sh"
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

shellcheck --shell=bash "${existing_files[@]}"
