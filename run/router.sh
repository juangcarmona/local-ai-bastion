#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[start] router"

# Load env
if [[ ! -f "${REPO_ROOT}/.env" ]]; then
  echo "[err] .env missing"
  exit 1
fi
# shellcheck disable=SC1090
set -a
source "${REPO_ROOT}/.env"
set +a

# Sanity checks
: "${VENV_DIR:?}"
: "${LITELLM_PORT:?}"
: "${CHAT_MODEL_NAME:?}"
: "${CODE_MODEL_NAME:?}"
: "${EMBED_MODEL_NAME:?}"

# Activate venv
# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"

mkdir -p "${LOG_DIR}" "${PID_DIR}" "${REPO_ROOT}/litellm"

# Generate config from template
envsubst < "${REPO_ROOT}/litellm/config.template.yaml" \
  > "${REPO_ROOT}/litellm/config.yaml"

LOG="${LOG_DIR}/router.log"
PID="${PID_DIR}/router.pid"

nohup litellm \
  --host 0.0.0.0 \
  --port "${LITELLM_PORT}" \
  --config "${REPO_ROOT}/litellm/config.yaml" \
  > "${LOG}" 2>&1 &

echo $! > "${PID}"
echo "[ok] router pid $(cat "${PID}")"
