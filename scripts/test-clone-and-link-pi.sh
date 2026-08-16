#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_under_test="$repo_root/clone_and_link.sh"
settings_source="$repo_root/files/.pi/agent/settings.json"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

fail() {
  echo "$1" >&2
  exit 1
}

assert_file_exists() {
  local path="$1"
  local message="$2"

  if [ ! -f "$path" ]; then
    fail "$message"
  fi
}

assert_not_symlink() {
  local path="$1"
  local message="$2"

  if [ -L "$path" ]; then
    fail "$message"
  fi
}

assert_symlink() {
  local path="$1"
  local message="$2"

  if [ ! -L "$path" ]; then
    fail "$message"
  fi
}

assert_same_content() {
  local left="$1"
  local right="$2"
  local message="$3"

  if ! cmp -s "$left" "$right"; then
    fail "$message"
  fi
}

setup_dotfiles_repo() {
  local home_dir="$1"
  local origin_dir="$2"

  mkdir -p "$home_dir/.dot-files"
  cp -R "$repo_root/files" "$home_dir/.dot-files/"

  (
    cd "$home_dir/.dot-files" || exit 1
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add files
    git commit -q -m "Initial test repo"
    git branch -M main
    git init --bare -q "$origin_dir"
    git remote add origin "$origin_dir"
    git push -q -u origin main
  )
}

run_preserves_existing_auth_test() {
  local case_dir="$tmp_dir/preserve-existing-auth"
  local home_dir="$case_dir/home"
  local auth_file="$home_dir/.pi/agent/auth.json"
  local expected_auth="$case_dir/expected-auth.json"

  mkdir -p "$home_dir/.pi/agent"
  printf '{\n  "openai": {\n    "type": "api_key",\n    "key": "test-key"\n  }\n}\n' > "$auth_file"
  cp "$auth_file" "$expected_auth"

  setup_dotfiles_repo "$home_dir" "$case_dir/origin.git"

  HOME="$home_dir" bash "$script_under_test" >/dev/null

  assert_file_exists "$auth_file" "existing Pi auth.json should be preserved"
  assert_same_content "$auth_file" "$expected_auth" "existing Pi auth.json content changed"
  assert_not_symlink "$home_dir/.pi" "home .pi directory should not be replaced with a symlink"
  assert_file_exists "$home_dir/.pi/agent/settings.json" "settings.json should be installed"
  assert_same_content "$home_dir/.pi/agent/settings.json" "$settings_source" "settings.json content mismatch"
}

run_installs_settings_on_fresh_home_test() {
  local case_dir="$tmp_dir/fresh-home"
  local home_dir="$case_dir/home"

  setup_dotfiles_repo "$home_dir" "$case_dir/origin.git"

  HOME="$home_dir" bash "$script_under_test" >/dev/null

  assert_not_symlink "$home_dir/.pi" "home .pi directory should be a real directory on a fresh install"
  assert_file_exists "$home_dir/.pi/agent/settings.json" "settings.json should be installed on a fresh home"
  assert_same_content "$home_dir/.pi/agent/settings.json" "$settings_source" "settings.json content mismatch on a fresh home"

  if [ -e "$home_dir/.pi/agent/auth.json" ]; then
    fail "auth.json should not be created on a fresh home"
  fi
}

run_repairs_legacy_pi_symlink_test() {
  local case_dir="$tmp_dir/repair-legacy-symlink"
  local home_dir="$case_dir/home"
  local auth_file="$home_dir/.pi/agent/auth.json"
  local expected_auth="$case_dir/expected-auth.json"
  local repo_auth_file="$home_dir/.dot-files/files/.pi/agent/auth.json"

  setup_dotfiles_repo "$home_dir" "$case_dir/origin.git"

  (
    cd "$home_dir" || exit 1
    ln -s ".dot-files/files/.pi" ".pi"
  )

  mkdir -p "$home_dir/.pi/agent"
  printf '{\n  "openai": {\n    "type": "api_key",\n    "key": "migrated-key"\n  }\n}\n' > "$auth_file"
  cp "$auth_file" "$expected_auth"

  HOME="$home_dir" bash "$script_under_test" >/dev/null

  assert_not_symlink "$home_dir/.pi" "legacy ~/.pi symlink should be repaired into a real directory"
  assert_file_exists "$auth_file" "Pi auth.json should survive repairing the legacy symlink"
  assert_same_content "$auth_file" "$expected_auth" "Pi auth.json content changed during legacy symlink repair"
  assert_file_exists "$home_dir/.pi/agent/settings.json" "settings.json should still be installed after legacy symlink repair"
  assert_same_content "$home_dir/.pi/agent/settings.json" "$settings_source" "settings.json content mismatch after legacy symlink repair"

  if [ -e "$repo_auth_file" ]; then
    fail "legacy auth.json should be removed from the dot-files checkout"
  fi
}

run_preserves_existing_directories_and_backs_up_conflicts_test() {
  local case_dir="$tmp_dir/preserves-existing-directories"
  local home_dir="$case_dir/home"
  local custom_config="$home_dir/.config/custom/user.txt"
  local private_aliases="$home_dir/.zsh/private-aliases"
  local backup_vimrc
  local backup_count_before
  local backup_count_after

  setup_dotfiles_repo "$home_dir" "$case_dir/origin.git"

  mkdir -p "$(dirname "$custom_config")" "$(dirname "$private_aliases")"
  printf 'keep custom config\n' > "$custom_config"
  printf "alias private-marker='printf private'\n" > "$private_aliases"
  printf 'old vim config\n' > "$home_dir/.vimrc"

  HOME="$home_dir" bash "$script_under_test" >/dev/null

  assert_file_exists "$custom_config" "unmanaged files in an existing .config directory should be preserved"
  assert_file_exists "$private_aliases" "private aliases in an existing .zsh directory should be preserved"
  assert_symlink "$home_dir/.config/ghostty" "managed config directories should be linked into an existing .config directory"
  assert_symlink "$home_dir/.zsh/aliases" "managed zsh files should be linked into an existing .zsh directory"
  assert_symlink "$home_dir/.vimrc" "a conflicting managed file should be replaced with a link"

  backup_vimrc=$(find "$home_dir/.dot-files-backup" -type f -path '*/.vimrc' -print -quit)
  assert_file_exists "$backup_vimrc" "a conflicting managed file should be backed up"

  if [ "$(cat "$custom_config")" != "keep custom config" ]; then
    fail "custom config content changed during install"
  fi

  if [ "$(cat "$private_aliases")" != "alias private-marker='printf private'" ]; then
    fail "private alias content changed during install"
  fi

  if [ "$(cat "$backup_vimrc")" != "old vim config" ]; then
    fail "backed-up vim config content changed"
  fi

  backup_count_before=$(find "$home_dir/.dot-files-backup" -mindepth 1 -maxdepth 1 -type d | wc -l)
  HOME="$home_dir" bash "$script_under_test" >/dev/null
  backup_count_after=$(find "$home_dir/.dot-files-backup" -mindepth 1 -maxdepth 1 -type d | wc -l)

  if [ "$backup_count_after" -ne "$backup_count_before" ]; then
    fail "an idempotent second install should not create another backup"
  fi
}

run_starts_cleanly_without_optional_tools_test() {
  local case_dir="$tmp_dir/clean-shell-startup"
  local home_dir="$case_dir/home"

  setup_dotfiles_repo "$home_dir" "$case_dir/origin.git"
  HOME="$home_dir" bash "$script_under_test" >/dev/null

  HOME="$home_dir" USER="test-user" ZDOTDIR="$home_dir" zsh -lic 'print -r -- SHELL_READY' >"$case_dir/stdout" 2>"$case_dir/stderr"

  if [ "$(cat "$case_dir/stdout")" != "SHELL_READY" ]; then
    fail "a login zsh shell should start successfully"
  fi

  if [ -s "$case_dir/stderr" ]; then
    cat "$case_dir/stderr" >&2
    fail "a login zsh shell should not print errors when optional tools are absent"
  fi
}

run_preserves_existing_auth_test
run_installs_settings_on_fresh_home_test
run_repairs_legacy_pi_symlink_test
run_preserves_existing_directories_and_backs_up_conflicts_test
run_starts_cleanly_without_optional_tools_test

echo "clone_and_link tests passed"
