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
