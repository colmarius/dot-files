#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

backup_root=""

backup_existing_entry() {
    local dest="$1"
    local relative_dest="${dest#"$HOME"/}"

    if [ -z "$backup_root" ]; then
      backup_root="$HOME/.dot-files-backup/$(date +%Y%m%d-%H%M%S)-$$"
      mkdir -p "$backup_root"
      echo_warn "Existing managed entries will be backed up under $backup_root"
    fi

    mkdir -p "$backup_root/$(dirname "$relative_dest")"
    mv "$dest" "$backup_root/$relative_dest"
    echo_info "✓ Backed up existing $relative_dest"
}

install_entry() {
    local src="$1"
    local dest="$2"
    local child

    if [ -L "$dest" ] && [ "$dest" -ef "$src" ]; then
      echo_info "✓ Already linked: ${dest#"$HOME"/}"
      return 0
    fi

    if [ -d "$src" ] && [ ! -L "$src" ] && [ -d "$dest" ] && [ ! -L "$dest" ]; then
      echo_info "Merging managed entries into existing directory: ${dest#"$HOME"/}"

      while IFS= read -r -d '' child; do
        install_entry "$child" "$dest/$(basename "$child")"
      done < <(find "$src" -mindepth 1 -maxdepth 1 -print0)

      return 0
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
      backup_existing_entry "$dest"
    fi

    mkdir -p "$(dirname "$dest")"

    if ln -vs "$src" "$dest" 2>/dev/null; then
      echo_info "✓ Created symlink: ${dest#"$HOME"/}"
      return 0
    fi

    echo_warn "Symlink failed for ${dest#"$HOME"/}; copying it instead"

    if cp -R "$src" "$dest"; then
      echo_info "✓ Copied: ${dest#"$HOME"/}"
    else
      echo_error "Failed to install: ${dest#"$HOME"/}"
      return 1
    fi
}

is_legacy_pi_repo_symlink() {
    local pi_dir="$HOME/.pi"
    local repo_pi_dir="$HOME/.dot-files/files/.pi"
    local link_target

    if [ ! -L "$pi_dir" ]; then
      return 1
    fi

    link_target=$(readlink "$pi_dir")
    [ "$link_target" = ".dot-files/files/.pi" ] || [ "$link_target" = "$repo_pi_dir" ]
}

repair_pi_directory_if_needed() {
    local pi_dir="$HOME/.pi"
    local repo_pi_dir="$HOME/.dot-files/files/.pi"
    local temp_pi_dir

    if ! is_legacy_pi_repo_symlink; then
      return 0
    fi

    echo_warn "Detected legacy ~/.pi symlink to dot-files; converting it back to a real directory"

    temp_pi_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-pi.XXXXXX")
    cp -R "$pi_dir/." "$temp_pi_dir/"

    rm -f "$pi_dir"
    mkdir -p "$pi_dir"
    cp -R "$temp_pi_dir/." "$pi_dir/"
    rm -rf "$temp_pi_dir"

    if [ -f "$repo_pi_dir/agent/auth.json" ] && [ -f "$pi_dir/agent/auth.json" ]; then
      rm -f "$repo_pi_dir/agent/auth.json"
      echo_info "✓ Moved Pi auth.json out of the dot-files checkout"
    fi
}

install_pi_settings_file() {
    local src="$HOME/.dot-files/files/.pi/agent/settings.json"
    local dest="$HOME/.pi/agent/settings.json"

    if [ ! -e "$src" ]; then
      return 0
    fi

    echo_info "Processing Pi settings file"
    install_entry "$src" "$dest"
}

cd "$HOME"

  # Clone or update dot-files.
  if [ -e ".dot-files" ] || [ -L ".dot-files" ]; then
    if git -C ".dot-files" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo_info "Updating existing dot-files repository..."
      git -C ".dot-files" pull --rebase
    else
      echo_error "$HOME/.dot-files exists but is not a Git repository; refusing to replace it"
      exit 1
    fi
  else
    echo_info "Cloning dot-files repository..."
    git clone "https://github.com/colmarius/dot-files.git" ".dot-files"
  fi

  # Process each top-level entry. Existing real directories are merged so
  # unrelated files such as private shell aliases are preserved.
  while IFS= read -r -d '' f; do
    basename_f=$(basename "$f")

    if [ "$basename_f" = ".pi" ]; then
      echo_info "Skipping top-level .pi entry; Pi settings are managed separately"
      continue
    fi

    echo_info "Processing: $basename_f"
    install_entry "$f" "$HOME/$basename_f"
  done < <(find "$HOME/.dot-files/files" -mindepth 1 -maxdepth 1 -print0)

  repair_pi_directory_if_needed
  install_pi_settings_file

  echo_info "Dot-files setup complete!"
