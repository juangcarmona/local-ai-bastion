#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load env
# shellcheck disable=SC1090
set -a
source "${REPO_ROOT}/.env"
set +a

# Activate venv
# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"

mkdir -p "${LOG_DIR}" "${PID_DIR}"

LOG="${LOG_DIR}/embed.log"
PID="${PID_DIR}/embed.pid"

nohup python -m vllm.entrypoints.openai.api_server \
  --host 0.0.0.0 \
  --port "${EMBED_PORT}" \
  --model "${EMBED_MODEL}" \
  --served-model-name "${EMBED_MODEL_NAME}" \
  --max-model-len "${EMBED_CTX}" \
  --gpu-memory-utilization "${EMBED_GPU_UTIL}" \
  --max-num-seqs "${EMBED_MAX_NUM_SEQS}" \
  > "${LOG}" 2>&1 &

echo $! > "${PID}"
echo "[ok] embed pid $(cat "${PID}")"
