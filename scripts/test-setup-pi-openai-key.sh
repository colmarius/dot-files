#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_under_test="$repo_root/scripts/setup-pi-openai-key.sh"

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

assert_contains() {
  local path="$1"
  local expected="$2"
  local message="$3"

  if ! grep -Fq "$expected" "$path"; then
    fail "$message"
  fi
}

assert_not_exists() {
  local path="$1"
  local message="$2"

  if [ -e "$path" ]; then
    fail "$message"
  fi
}

make_fake_macos_bin() {
  local bin_dir="$1"

  mkdir -p "$bin_dir"

  cat >"$bin_dir/uname" <<'EOF'
#!/usr/bin/env bash
echo Darwin
EOF

  cat >"$bin_dir/security" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$SECURITY_LOG"
EOF

  chmod +x "$bin_dir/uname" "$bin_dir/security"
}

run_setup_script() {
  local home_dir="$1"
  local fake_bin="$2"
  local security_log="$3"

  shift 3

  HOME="$home_dir" USER="test-user" SECURITY_LOG="$security_log" PATH="$fake_bin:$PATH" bash "$script_under_test" "$@"
}

assert_auth_json_state() {
  local auth_file="$1"
  local user_name="$2"
  local mode="$3"

  AUTH_FILE="$auth_file" USER_NAME="$user_name" MODE="$mode" node <<'EOF'
const fs = require('fs')

const authFile = process.env.AUTH_FILE
const userName = process.env.USER_NAME
const mode = process.env.MODE
const auth = JSON.parse(fs.readFileSync(authFile, 'utf8'))

if (!auth.anthropic || auth.anthropic.key !== 'existing-key') {
  throw new Error('anthropic auth entry should be preserved')
}

if (mode === 'set') {
  const expectedKey = `!security find-generic-password -a ${userName} -s pi-openai-api-key -w`

  if (!auth.openai || auth.openai.type !== 'api_key' || auth.openai.key !== expectedKey) {
    throw new Error('openai auth entry should be configured')
  }
} else if (Object.prototype.hasOwnProperty.call(auth, 'openai')) {
  throw new Error('openai auth entry should be removed')
}
EOF
}

run_rejects_legacy_pi_symlink_test() {
  local case_dir="$tmp_dir/rejects-legacy-symlink"
  local home_dir="$case_dir/home"
  local fake_bin="$case_dir/bin"
  local security_log="$case_dir/security.log"

  mkdir -p "$home_dir/.dot-files/files"
  cp -R "$repo_root/files/.pi" "$home_dir/.dot-files/files/"
  (
    cd "$home_dir" || exit 1
    ln -s ".dot-files/files/.pi" ".pi"
  )
  make_fake_macos_bin "$fake_bin"

  if printf 'test-key\n' | run_setup_script "$home_dir" "$fake_bin" "$security_log" set >"$case_dir/stdout" 2>"$case_dir/stderr"; then
    fail "setup script should reject the legacy ~/.pi repo symlink"
  fi

  assert_contains "$case_dir/stderr" "Run clone_and_link.sh once to repair it" "legacy symlink error should explain how to repair ~/.pi"

  if [ -s "$security_log" ]; then
    fail "security should not be called when ~/.pi still points into the repo"
  fi

  assert_not_exists "$home_dir/.dot-files/files/.pi/agent/auth.json" "legacy repo symlink should not recreate auth.json inside the repo"
}

run_set_merges_auth_test() {
  local case_dir="$tmp_dir/set-merges-auth"
  local home_dir="$case_dir/home"
  local fake_bin="$case_dir/bin"
  local security_log="$case_dir/security.log"
  local auth_file="$home_dir/.pi/agent/auth.json"

  mkdir -p "$home_dir/.pi/agent"
  cat >"$auth_file" <<'EOF'
{
  "anthropic": {
    "type": "api_key",
    "key": "existing-key"
  }
}
EOF
  make_fake_macos_bin "$fake_bin"

  printf 'test-key\n' | run_setup_script "$home_dir" "$fake_bin" "$security_log" set >/dev/null

  assert_file_exists "$auth_file" "setup script should create auth.json when configuring Pi"
  assert_contains "$security_log" "add-generic-password" "setup script should store the secret in Keychain on set"
  assert_auth_json_state "$auth_file" "test-user" "set"
}

run_unset_preserves_other_auth_test() {
  local case_dir="$tmp_dir/unset-preserves-other-auth"
  local home_dir="$case_dir/home"
  local fake_bin="$case_dir/bin"
  local security_log="$case_dir/security.log"
  local auth_file="$home_dir/.pi/agent/auth.json"

  mkdir -p "$home_dir/.pi/agent"
  cat >"$auth_file" <<'EOF'
{
  "openai": {
    "type": "api_key",
    "key": "!security find-generic-password -a test-user -s pi-openai-api-key -w"
  },
  "anthropic": {
    "type": "api_key",
    "key": "existing-key"
  }
}
EOF
  make_fake_macos_bin "$fake_bin"

  run_setup_script "$home_dir" "$fake_bin" "$security_log" unset >/dev/null

  assert_file_exists "$auth_file" "unset should preserve auth.json when other providers remain"
  assert_contains "$security_log" "delete-generic-password" "setup script should remove the secret from Keychain on unset"
  assert_auth_json_state "$auth_file" "test-user" "unset"
}

run_invalid_auth_json_fails_before_keychain_test() {
  local case_dir="$tmp_dir/invalid-auth-json"
  local home_dir="$case_dir/home"
  local fake_bin="$case_dir/bin"
  local security_log="$case_dir/security.log"
  local auth_file="$home_dir/.pi/agent/auth.json"

  mkdir -p "$home_dir/.pi/agent"
  printf '{ invalid json\n' >"$auth_file"
  make_fake_macos_bin "$fake_bin"

  if printf 'test-key\n' | run_setup_script "$home_dir" "$fake_bin" "$security_log" set >"$case_dir/stdout" 2>"$case_dir/stderr"; then
    fail "setup script should fail when auth.json is malformed"
  fi

  if [ -s "$security_log" ]; then
    fail "security should not be called when auth.json is malformed"
  fi
}

run_rejects_legacy_pi_symlink_test
run_set_merges_auth_test
run_unset_preserves_other_auth_test
run_invalid_auth_json_fails_before_keychain_test

echo "setup-pi-openai-key tests passed"
