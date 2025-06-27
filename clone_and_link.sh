#!/bin/bash

set -e  # Exit on any error

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

pushd "$HOME"

  # Clone or update dot-files
  if [ -d ".dot-files" ]; then
    echo_info "Updating existing dot-files repository..."
    pushd ".dot-files"
      git pull --rebase
    popd
  else
    echo_info "Cloning dot-files repository..."
    git clone "git@github.com:colmarius/dot-files.git" ".dot-files"
  fi

  # Process each file/directory
  ls -1d .dot-files/files/* .dot-files/files/.* 2>/dev/null | while read f; do
    # Skip special directories
    [ "$f" == '.dot-files/files/.' ] && continue
    [ "$f" == '.dot-files/files/..' ] && continue
    [ "$f" == '.dot-files/files/.git' ] && continue

    basename_f=$(basename "$f")

    if [ -d "$f" ]; then
      echo_info "Processing directory: $basename_f"

      # Try to create symlink for directory
      if ln -vsf "$f" . 2>/dev/null; then
        echo_info "✓ Created symlink for directory: $basename_f"
      else
        echo_warn "Symlink failed for directory: $basename_f"
        echo_info "Attempting to copy directory instead..."

        # Remove existing directory if it exists
        if [ -d "$basename_f" ]; then
          rm -rf "$basename_f"
        fi

        # Copy the directory
        if cp -r "$f" .; then
          echo_info "✓ Copied directory: $basename_f"
        else
          echo_error "Failed to copy directory: $basename_f"
        fi
      fi
    else
      echo_info "Processing file: $basename_f"

      # For files, always try symlink first
      if ln -vsf "$f" . 2>/dev/null; then
        echo_info "✓ Created symlink for file: $basename_f"
      else
        echo_warn "Symlink failed for file: $basename_f"
        echo_info "Attempting to copy file instead..."

        # Remove existing file if it exists
        if [ -f "$basename_f" ]; then
          rm -f "$basename_f"
        fi

        # Copy the file
        if cp "$f" .; then
          echo_info "✓ Copied file: $basename_f"
        else
          echo_error "Failed to copy file: $basename_f"
        fi
      fi
    fi
  done

  echo_info "Dot-files setup complete!"

popd
