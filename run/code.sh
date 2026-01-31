#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

require_venv

require_env HOST
require_env CODE_PORT
require_env CODE_MODEL
require_env CODE_MODEL_NAME
require_env CODE_CTX
require_env CODE_MAX_NUM_SEQS
require_env CODE_GPU_UTIL

export HF_HOME="${HF_HOME:-${REPO_ROOT}/.hf}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-${HF_HOME}/transformers}"
mkdir -p "${HF_HOME}" "${TRANSFORMERS_CACHE}"

LOG="${LOG_DIR}/code.log"

start_bg "code" "${LOG}" \
  python -m vllm.entrypoints.openai.api_server \
    --host "${HOST}" \
    --port "${CODE_PORT}" \
    --model "${CODE_MODEL}" \
    --served-model-name "${CODE_MODEL_NAME}" \
    --dtype "half" \
    --max-model-len "${CODE_CTX}" \
    --gpu-memory-utilization "${CODE_GPU_UTIL}" \
    --max-num-seqs "${CODE_MAX_NUM_SEQS}" \
    --disable-log-requests
