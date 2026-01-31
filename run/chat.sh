#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

require_env HOST
require_env CHAT_PORT
require_env CHAT_GGUF
require_env CHAT_MODEL_NAME
require_env CHAT_CTX
require_env CHAT_PARALLEL
require_env CHAT_BATCH
require_env CHAT_THREADS
require_env LLAMA_SERVER_BIN

if [[ ! -x "${LLAMA_SERVER_BIN}" ]]; then
  echo "[err] llama-server missing at ${LLAMA_SERVER_BIN}. Run: ./run/install.sh"
  exit 1
fi

LOG="${LOG_DIR}/chat.log"

# llama.cpp OpenAI-compatible server
start_bg "chat" "${LOG}" \
  "${LLAMA_SERVER_BIN}" \
    --host "${HOST}" \
    --port "${CHAT_PORT}" \
    --model "${CHAT_GGUF}" \
    --alias "${CHAT_MODEL_NAME}" \
    --ctx-size "${CHAT_CTX}" \
    --parallel "${CHAT_PARALLEL}" \
    --batch-size "${CHAT_BATCH}" \
    --threads "${CHAT_THREADS}" \
    --n-gpu-layers -1 \
    --metrics
