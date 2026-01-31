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
