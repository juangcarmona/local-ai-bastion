
# Local AI Bastion

**3 local models · 1 OpenAI-compatible endpoint**

A stable local LLM serving setup with **strict resource control**, designed to run multiple models concurrently on a single GPU without VRAM thrash.

---

## Architecture Overview

```
                    ┌──────────────────────┐
                    │     LiteLLM Proxy    │
                    │  OpenAI-compatible   │
                    │     :${LITELLM_PORT} │
                    └─────────┬────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────────────┐     ┌───────────────┐     ┌─────────────────┐
│ Chat (GGUF)   │     │ Code (HF/AWQ) │     │ Embeddings (HF) │
│ llama.cpp     │     │ vLLM server   │     │ vLLM server     │
│ :${CHAT_PORT} │     │ :${CODE_PORT} │     │ :${EMBED_PORT}  │
└───────────────┘     └───────────────┘     └─────────────────┘
```

### Roles

####  Front door

LiteLLM proxy → Single OpenAI-compatible API

#### Chat 

`llama.cpp` (`llama-server`) serving GGUF → `${CHAT_MODEL_NAME}` @ `:${CHAT_PORT}`

#### Code

vLLM OpenAI server (HF / AWQ) → `${CODE_MODEL_NAME}` @ `:${CODE_PORT}`

#### Embeddings

vLLM OpenAI server → `${EMBED_MODEL_NAME}` @ `:${EMBED_PORT}`


---

## CUDA Prerequisites

CUDA is required **only to compile and run GPU backends**.

### WSL2 (Windows + Ubuntu)

```bash
./run/install-cuda-wsl.sh
```

* Installs **CUDA Toolkit only**
* NVIDIA drivers must be installed on **Windows**
* Does **not** modify shell configuration

### Ubuntu (bare-metal)

```bash
./run/install-cuda-ubuntu.sh
```

* Installs **NVIDIA driver + CUDA Toolkit**
* Reboot may be required

---



Sí. **100 % de acuerdo**.
Esto **debe formar parte de los scripts**. Si no, cualquiera que clone el repo **se va a estrellar exactamente donde tú**.

La clave es **cómo** integrarlo sin hacer barbaridades.

Voy a darte **las versiones finales correctas** de ambos scripts, incorporando:

* creación del **symlink canónico `/usr/local/cuda`**
* exposición **global y no intrusiva** vía `/etc/profile.d/cuda.sh`
* idempotencia
* mensajes claros
* sin tocar `.zshrc`, `.bashrc`, p10k, etc.

---

## Principio (importante)

Esto **sí es responsabilidad del repo**, porque:

* El repo **compila código CUDA**
* CUDA en Ubuntu 24.04 **no es usable sin esto**
* NVIDIA **no lo hace por defecto**
* No es una preferencia del usuario, es un requisito técnico

Lo que **no** hace el repo:

* no toca shells de usuario
* no hace magia silenciosa
* no asume paths raros

---

# ✅ Script final — Ubuntu bare-metal

📄 `run/install-cuda-ubuntu.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[cuda][ubuntu] Installing NVIDIA Driver + CUDA Toolkit (Ubuntu 24.04)"

# Refuse WSL
if grep -qi microsoft /proc/version; then
  echo "[err] Detected WSL. Use install-cuda-wsl.sh instead."
  exit 1
fi

# Add NVIDIA repo
if ! dpkg -l | grep -q cuda-keyring; then
  echo "[cuda][ubuntu] Adding NVIDIA CUDA repository"
  wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
fi

sudo apt update

# Install driver + toolkit
sudo apt install -y nvidia-driver-550 cuda-toolkit-12-5

# Create canonical symlink
if [[ ! -e /usr/local/cuda ]]; then
  echo "[cuda][ubuntu] Creating /usr/local/cuda symlink"
  sudo ln -sfn /usr/local/cuda-12.5 /usr/local/cuda
fi

# Install global CUDA env (idempotent)
if [[ ! -f /etc/profile.d/cuda.sh ]]; then
  echo "[cuda][ubuntu] Installing global CUDA environment"
  sudo tee /etc/profile.d/cuda.sh >/dev/null <<'EOF'
export CUDA_HOME=/usr/local/cuda
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
EOF
fi

# Verify
source /etc/profile.d/cuda.sh
nvidia-smi
nvcc --version

echo "[cuda][ubuntu] Done. Reboot may be required."
```

---

# ✅ Script final — WSL2

📄 `run/install-cuda-wsl.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[cuda][wsl] Installing CUDA Toolkit for WSL (Ubuntu 24.04)"

# Sanity checks
if ! grep -qi microsoft /proc/version; then
  echo "[err] This script is for WSL only."
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "[err] nvidia-smi not found. Install NVIDIA drivers on Windows first."
  exit 1
fi

# Add NVIDIA repo
if ! dpkg -l | grep -q cuda-keyring; then
  echo "[cuda][wsl] Adding NVIDIA CUDA repository"
  wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
fi

sudo apt update

# Install toolkit only
sudo apt install -y cuda-toolkit-12-5

# Create canonical symlink
if [[ ! -e /usr/local/cuda ]]; then
  echo "[cuda][wsl] Creating /usr/local/cuda symlink"
  sudo ln -sfn /usr/local/cuda-12.5 /usr/local/cuda
fi

# Install global CUDA env (idempotent)
if [[ ! -f /etc/profile.d/cuda.sh ]]; then
  echo "[cuda][wsl] Installing global CUDA environment"
  sudo tee /etc/profile.d/cuda.sh >/dev/null <<'EOF'
export CUDA_HOME=/usr/local/cuda
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
EOF
fi

# Verify
source /etc/profile.d/cuda.sh
nvcc --version

echo "[cuda][wsl] Done."
```

---


### CUDA setup (required for llama.cpp)

Ubuntu 24.04 requires one extra step to make CUDA discoverable by CMake
(`/usr/local/cuda` symlink + global PATH).

This repo provides scripts that handle this for you.

#### WSL2
```bash
./run/install-cuda-wsl.sh
````

#### Ubuntu bare-metal

```bash
./run/install-cuda-ubuntu.sh
```

These scripts:

* install the CUDA Toolkit
* create `/usr/local/cuda`
* expose CUDA system-wide via `/etc/profile.d`
* do not modify user shell configs

> NOTE: I only tried the WSL version, feel free to blame on me if it does not work for you... Or generate a workaround that works and a PR with the fix.

## Setup

### 1. Configure environment

```bash
cp .env.example .env
```

Edit `.env`:

* Set `CHAT_GGUF` to your GGUF file path
* Optionally adjust `MODEL_DIR`, ports, and memory caps

---

### 2. Install dependencies and build components

```bash
chmod +x run/*.sh
./run/install.sh
```

This will:

* Create a dedicated Python venv
* Install pinned Python dependencies
* Build `llama.cpp` with CUDA support
* Place `llama-server` in `./bin`

---

### 3. Launch all services

```bash
./run/launch.sh
```

---

### 4. Test

```bash
./run/test.sh
```

Runs basic health checks through the LiteLLM front door.

---

### 5. Stop everything

```bash
./run/stop.sh
```

---

## Logs

Each component logs independently:

* `logs/chat.log`   — llama.cpp (chat)
* `logs/code.log`   — vLLM (code)
* `logs/embed.log`  — vLLM (embeddings)
* `logs/router.log` — LiteLLM proxy

---

## Quickstart (exact commands)

```bash
cd ~/dev/local-ai-bastion

cp .env.example .env
# edit .env (CHAT_GGUF is required)

chmod +x run/*.sh

./run/install.sh
./run/launch.sh
./run/test.sh
./run/stop.sh
```

---

## VRAM Budgeting (A6000 · 48 GB)

Designed to keep **all three models running concurrently** without OOM.

### Target GPU caps

* **CODE (Qwen2.5-Coder-14B-AWQ)**
  `CODE_GPU_UTIL=0.32` → ~15.4 GB

* **EMBED (bge-small)**
  `EMBED_GPU_UTIL=0.06` → ~2.9 GB

* **CHAT (GLM-4.7-Flash GGUF)**
  Remaining ~29 GB (minus CUDA overhead)

### Why this works

* vLLM memory pressure is bounded by:

  * context length
  * concurrent sequences
  * explicit GPU utilization caps

Configured defaults:

* `CODE_CTX=8192`, `CODE_MAX_NUM_SEQS=6`
* `EMBED_CTX=512`, `EMBED_MAX_NUM_SEQS=32`
* llama.cpp uses fixed `--ctx-size` and `--parallel`

---

### If you still hit OOM (apply in order)

1. Reduce `CODE_MAX_NUM_SEQS`: `6 → 4`
2. Reduce `CHAT_PARALLEL`: `2 → 1`
3. Reduce context: `8192 → 6144`
4. Reduce `CODE_GPU_UTIL`: `0.32 → 0.28`

---

## Design Principles

* Explicit resource caps (no “best effort” allocation)
* No hidden defaults for critical versions
* One front door, many backends
* Fail fast on misconfiguration

