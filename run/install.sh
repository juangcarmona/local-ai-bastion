#!/usr/bin/env bash
set -euo pipefail
# Installs python deps in VENV_DIR and builds llama.cpp (pinned).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

# Load env (mandatory)
if [[ ! -f "${REPO_ROOT}/.env" ]]; then
  echo "[err] .env missing. Copy .env.example and edit it."
  exit 1
fi
# shellcheck disable=SC1090
source "${REPO_ROOT}/.env"

if [[ -z "${VENV_DIR:-}" ]]; then
  echo "[err] VENV_DIR not set in .env"
  exit 1
fi

echo "[py] create venv: ${VENV_DIR}"
rm -rf "${VENV_DIR}"
python3 -m venv "${VENV_DIR}"

# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"

python -m pip install --upgrade "pip<25" "setuptools<75" "wheel<1"
python -m pip install -c "${REPO_ROOT}/constraints.txt" -r "${REPO_ROOT}/requirements.txt"

# =========================
# llama.cpp (pinned)
# =========================

: "${LLAMA_CPP_DIR:=${REPO_ROOT}/.deps/llama.cpp}"
: "${LLAMA_CPP_BUILD_DIR:=${LLAMA_CPP_DIR}/build}"
: "${LLAMA_SERVER_BIN:=${REPO_ROOT}/bin/llama-server}"

if [[ -z "${LLAMA_CPP_GIT_REF:-}" ]]; then
  echo "[err] LLAMA_CPP_GIT_REF not set in .env"
  exit 1
fi

mkdir -p "${REPO_ROOT}/.deps" "${REPO_ROOT}/bin"

if [[ ! -d "${LLAMA_CPP_DIR}/.git" ]]; then
  echo "[llama.cpp] clone"
  git clone https://github.com/ggerganov/llama.cpp "${LLAMA_CPP_DIR}"
fi

echo "[llama.cpp] checkout ${LLAMA_CPP_GIT_REF}"
git -C "${LLAMA_CPP_DIR}" fetch --all --tags
git -C "${LLAMA_CPP_DIR}" checkout "${LLAMA_CPP_GIT_REF}"

echo "[llama.cpp] build (CUDA)"
cmake -S "${LLAMA_CPP_DIR}" -B "${LLAMA_CPP_BUILD_DIR}" \
  -DGGML_CUDA=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build "${LLAMA_CPP_BUILD_DIR}" -j

if [[ -x "${LLAMA_CPP_BUILD_DIR}/bin/llama-server" ]]; then
  cp -f "${LLAMA_CPP_BUILD_DIR}/bin/llama-server" "${LLAMA_SERVER_BIN}"
elif [[ -x "${LLAMA_CPP_BUILD_DIR}/llama-server" ]]; then
  cp -f "${LLAMA_CPP_BUILD_DIR}/llama-server" "${LLAMA_SERVER_BIN}"
else
  echo "[err] llama-server not found in build output"
  exit 1
fi

chmod +x "${LLAMA_SERVER_BIN}"
echo "[ok] install complete"
