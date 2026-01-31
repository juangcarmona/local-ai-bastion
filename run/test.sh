#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

require_env HOST
require_env LITELLM_PORT
require_env CHAT_MODEL_NAME
require_env CODE_MODEL_NAME
require_env EMBED_MODEL_NAME

BASE="http://${HOST}:${LITELLM_PORT}/v1"

echo "== models =="
curl -s "${BASE}/models" | head -c 2000
echo
echo

echo "== chat (glm) =="
curl -s "${BASE}/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${CHAT_MODEL_NAME}\",
    \"messages\": [
      {\"role\":\"system\",\"content\":\"You are concise.\"},
      {\"role\":\"user\",\"content\":\"Reply with a 1-sentence status.\"}
    ],
    \"max_tokens\": 80,
    \"temperature\": 0
  }" | head -c 2000
echo
echo

echo "== code (qwen) =="
curl -s "${BASE}/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${CODE_MODEL_NAME}\",
    \"messages\": [
      {\"role\":\"system\",\"content\":\"You output only code.\"},
      {\"role\":\"user\",\"content\":\"Write a Python function add(a,b) with type hints.\"}
    ],
    \"max_tokens\": 120,
    \"temperature\": 0
  }" | head -c 2000
echo
echo

echo "== embed (bge) =="
curl -s "${BASE}/embeddings" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${EMBED_MODEL_NAME}\",
    \"input\": [\"hello world\", \"local embeddings\"]
  }" | head -c 2000
echo
