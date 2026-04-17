#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$repo_root/scripts/test-npm-run-local-completion.sh"
bash "$repo_root/scripts/test-clone-and-link-pi.sh"
bash "$repo_root/scripts/test-setup-pi-openai-key.sh"

echo "shell regression tests passed"
