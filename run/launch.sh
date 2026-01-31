#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

# Incremental bring-up (safe order):
# 1) code (biggest KV risk, shape it first)
# 2) embed (tiny)
# 3) chat (llama.cpp GGUF)
# 4) router (front door)
"${REPO_ROOT}/run/code.sh"
"${REPO_ROOT}/run/embed.sh"
"${REPO_ROOT}/run/chat.sh"
"${REPO_ROOT}/run/router.sh"

"${REPO_ROOT}/run/status.sh"
