#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/setup-pi-openai-key.sh set
  bash scripts/setup-pi-openai-key.sh unset

The `set` command stores the OpenAI API key in the macOS Keychain and
configures Pi to load it from ~/.pi/agent/auth.json on demand.

When run interactively, `set` prompts for the API key without echoing it.
When stdin is piped, `set` reads the API key from stdin.

The `unset` command removes the stored OpenAI API key from both macOS Keychain
and Pi auth config.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 1
fi

case "$1" in
  set|unset)
    action="$1"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [ "$(uname)" != "Darwin" ]; then
  echo "This script currently supports macOS only because it uses the security command." >&2
  exit 1
fi

if ! command -v security >/dev/null 2>&1; then
  echo "The macOS security command is required but was not found." >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required to merge Pi auth.json entries." >&2
  exit 1
fi

keychain_service="pi-openai-api-key"
auth_dir="$HOME/.pi/agent"
auth_file="$auth_dir/auth.json"
tmp_file="$(mktemp)"

cleanup() {
  stty echo 2>/dev/null || true
  rm -f "$tmp_file"
}

trap cleanup EXIT

if [ "$action" = "set" ]; then
  if [ ! -t 0 ] || [ ! -t 2 ]; then
    if ! read -r api_key; then
      echo "No API key received on stdin." >&2
      exit 1
    fi
  else
    printf 'OpenAI API key: ' >&2
    stty -echo
    read -r api_key
    stty echo
    printf '\n' >&2
  fi

  if [ -z "$api_key" ]; then
    echo "OpenAI API key cannot be empty." >&2
    exit 1
  fi

  mkdir -p "$auth_dir"
  chmod 700 "$HOME/.pi" "$auth_dir"

  security add-generic-password \
    -a "$USER" \
    -s "$keychain_service" \
    -w "$api_key" \
    -U >/dev/null
else
  security delete-generic-password \
    -a "$USER" \
    -s "$keychain_service" >/dev/null 2>&1 || true
fi

ACTION="$action" AUTH_FILE="$auth_file" USER_NAME="$USER" KEYCHAIN_SERVICE="$keychain_service" node <<'EOF' > "$tmp_file"
const fs = require('fs')

const action = process.env.ACTION
const authFile = process.env.AUTH_FILE
const userName = process.env.USER_NAME
const keychainService = process.env.KEYCHAIN_SERVICE

let auth = {}

if (fs.existsSync(authFile)) {
  auth = JSON.parse(fs.readFileSync(authFile, 'utf8'))
}

if (action === 'set') {
  auth.openai = {
    type: 'api_key',
    key: `!security find-generic-password -a ${userName} -s ${keychainService} -w`,
  }
} else {
  delete auth.openai
}

if (Object.keys(auth).length > 0) {
  process.stdout.write(`${JSON.stringify(auth, null, 2)}\n`)
}
EOF

if [ -s "$tmp_file" ]; then
  mv "$tmp_file" "$auth_file"
  chmod 600 "$auth_file"
else
  rm -f "$auth_file"
fi

if [ "$action" = "set" ]; then
  echo "Stored OpenAI API key in macOS Keychain service '$keychain_service'."
  echo "Configured Pi auth in $auth_file"
  echo
  echo "Test with: pi --model openai/gpt-5.4"
else
  echo "Removed OpenAI API key from macOS Keychain service '$keychain_service'."
  echo "Removed Pi OpenAI auth from $auth_file"
fi
