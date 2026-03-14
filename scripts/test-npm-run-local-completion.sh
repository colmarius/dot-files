#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
completion_file="$repo_root/files/.zsh/npm-run-local-completion"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

repo_dir="$tmp_dir/repo"
mkdir -p "$repo_dir/packages/app/src" "$repo_dir/packages/empty"

cat >"$repo_dir/package.json" <<'JSON'
{
  "scripts": {
    "root:build": "echo root"
  }
}
JSON

cat >"$repo_dir/packages/app/package.json" <<'JSON'
{
  "scripts": {
    "logs:monitor": "./scripts/monitor-agent-logs.sh",
    "review:checks:branch": "./scripts/repo/review-checks.sh branch"
  }
}
JSON

cat >"$repo_dir/packages/empty/package.json" <<'JSON'
{
  "scripts": {}
}
JSON

TEST_REPO="$repo_dir" COMPLETION_FILE="$completion_file" zsh <<'ZSH'
set -euo pipefail

fail() {
  print -u2 -- "$1"
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    fail "$message (expected: $expected, got: $actual)"
  fi
}

source "$COMPLETION_FILE"

cd "$TEST_REPO/packages/app/src"

package_json="$(_npm_run_local_find_package_json)"
assert_eq "$package_json" "$TEST_REPO/packages/app/package.json" "nearest package.json lookup failed"

scripts_output="$(_npm_run_local_get_scripts "$package_json")"
[[ "$scripts_output" == *$'logs:monitor\t./scripts/monitor-agent-logs.sh'* ]] || fail "missing logs:monitor script"
[[ "$scripts_output" == *$'review:checks:branch\t./scripts/repo/review-checks.sh branch'* ]] || fail "missing review:checks:branch script"

words=(npm run "")
CURRENT=3
_npm_run_local_should_complete || fail "expected completion for 'npm run <tab>'"

words=(npm run --silent "")
CURRENT=4
_npm_run_local_should_complete || fail "expected completion for 'npm run --silent <tab>'"

words=(npm --workspace explorer-agent run "")
CURRENT=5
_npm_run_local_should_complete || fail "expected completion for 'npm --workspace explorer-agent run <tab>'"

words=(npm run --workspace explorer-agent "")
CURRENT=5
_npm_run_local_should_complete || fail "expected completion for 'npm run --workspace explorer-agent <tab>'"

words=(npm run --workspace "")
CURRENT=4
if _npm_run_local_should_complete; then
  fail "did not expect completion while filling --workspace value"
fi

words=(npm run logs:monitor "")
CURRENT=4
if _npm_run_local_should_complete; then
  fail "did not expect script completion after selecting a script name"
fi

words=(npm test "")
CURRENT=3
if _npm_run_local_should_complete; then
  fail "did not expect interception for non-run subcommands"
fi

typeset -gi fallback_calls=0
typeset -gi compadd_calls=0

_npm_completion_fallback() {
  ((fallback_calls += 1))
  return 0
}

compadd() {
  ((compadd_calls += 1))
  return 0
}

words=(npm run "")
CURRENT=3
_npm_completion
((compadd_calls == 1)) || fail "expected one compadd call for npm run"
((fallback_calls == 0)) || fail "did not expect fallback for npm run"

words=(npm test "")
CURRENT=3
_npm_completion
((fallback_calls == 1)) || fail "expected fallback for non-run command"

cd "$TEST_REPO/packages/empty"
words=(npm run "")
CURRENT=3
_npm_completion
((compadd_calls == 1)) || fail "did not expect compadd when scripts are empty"
((fallback_calls == 1)) || fail "did not expect fallback when scripts are empty"
ZSH

NPM_RUN_LOCAL_COMPLETION_DISABLE=1 COMPLETION_FILE="$completion_file" zsh <<'ZSH'
set -euo pipefail
source "$COMPLETION_FILE"

if (( $+functions[_npm_run_local_find_package_json] )); then
  print -u2 -- "completion override should not load when disabled"
  exit 1
fi
ZSH

echo "npm run local completion tests passed"
