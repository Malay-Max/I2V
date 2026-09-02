#!/usr/bin/env bash
# ==============================================================================
# One-Click Setup Script: ComfyUI + Wan 2.1 (14B FP8) with Tailscale VPN
# Repo: https://github.com/Malay-Max/I2V
# Hardware: RTX 3090 (24GB VRAM) / Ubuntu/Debian GPU VPS / QuickPod / RunPod
# ==============================================================================

set -e # Exit immediately on error

echo "=========================================================="
echo "🚀 Starting Setup: ComfyUI + Wan 2.1 I2V + Tailscale"
echo "=========================================================="

# ------------------------------------------------------------------------------
# 1. System Dependencies & Tailscale Installation
# ------------------------------------------------------------------------------
echo "📦 [1/7] Installing system packages & Tailscale..."
export DEBIAN_FRONTEND=noninteractive
apt update -y && apt install -y git python3 python3-pip python3-venv libgl1 wget tmux ffmpeg curl iptables

if ! command -v tailscale &> /dev/null; then
    echo "🛡️ Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# ------------------------------------------------------------------------------
# 2. ComfyUI Core Installation & PyTorch (CUDA 12.6)
# ------------------------------------------------------------------------------
echo "🎨 [2/7] Installing ComfyUI & PyTorch..."
cd ~
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ~/ComfyUI

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source ~/ComfyUI/venv/bin/activate

pip install --upgrade pip
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126
pip install -r requirements.txt

# ------------------------------------------------------------------------------
# 3. Custom Node Packs Installation
# ------------------------------------------------------------------------------
echo "🧩 [3/7] Installing Custom Node Packs..."
cd ~/ComfyUI/custom_nodes

# ComfyUI-Manager
if [ ! -d "ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git
fi
pip install -r ComfyUI-Manager/requirements.txt || true

# ComfyUI-WanVideoWrapper
if [ ! -d "ComfyUI-WanVideoWrapper" ]; then
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git
fi
pip install -r ComfyUI-WanVideoWrapper/requirements.txt || true

# ComfyUI-KJNodes
if [ ! -d "ComfyUI-KJNodes" ]; then
    git clone https://github.com/kijai/ComfyUI-KJNodes.git
fi
pip install -r ComfyUI-KJNodes/requirements.txt || true

# ComfyUI-VideoHelperSuite
if [ ! -d "ComfyUI-VideoHelperSuite" ]; then
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
fi
pip install -r ComfyUI-VideoHelperSuite/requirements.txt || true

# ------------------------------------------------------------------------------
# 4. Model Directories
# ------------------------------------------------------------------------------
echo "📁 [4/7] Creating model directories..."
mkdir -p ~/ComfyUI/models/diffusion_models
mkdir -p ~/ComfyUI/models/text_encoders
mkdir -p ~/ComfyUI/models/vae
mkdir -p ~/ComfyUI/models/clip_vision
mkdir -p ~/ComfyUI/models/loras/WanVideo/Lightx2v
mkdir -p ~/ComfyUI/workflows

# ------------------------------------------------------------------------------
# 5. Download Model Weights
# ------------------------------------------------------------------------------
echo "⬇️ [5/7] Downloading verified model weights..."

# 5.1 Diffusion Model: Wan 2.1 14B 480p FP8 (~15.5 GB)
echo "--> Downloading Wan 2.1 14B I2V Diffusion Model..."
wget -c "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_1-I2V-14B-480p_fp8_e4m3fn_scaled_KJ.safetensors" \
     -O ~/ComfyUI/models/diffusion_models/Wan2_1-I2V-14B-480p_fp8_e4m3fn_scaled_KJ.safetensors

# 5.2 Text Encoder: UMT5-XXL FP8 (~5.5 GB)
echo "--> Downloading UMT5-XXL Text Encoder..."
wget -c "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-fp8_e4m3fn.safetensors" \
     -O ~/ComfyUI/models/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors

# 5.3 VAE: Wan 2.1 VAE (~250 MB)
echo "--> Downloading Wan 2.1 VAE..."
wget -c "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
     -O ~/ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors

# 5.4 CLIP Vision: Official clip_vision_h (~1.26 GB)
echo "--> Downloading CLIP Vision Model..."
wget -c "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
     -O ~/ComfyUI/models/clip_vision/clip_vision_h.safetensors

# 5.5 Lightx2v Distillation LoRA (~1.5 GB)
echo "--> Downloading Lightx2v Speedup LoRA..."
wget -c "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
     -O ~/ComfyUI/models/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors

# ------------------------------------------------------------------------------
# 6. Copy Workflow
# ------------------------------------------------------------------------------
echo "📋 [6/7] Copying I2V Workflow..."
cp ~/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/example_workflows/wanvideo_2_1_14B_I2V_example_03.json ~/ComfyUI/workflows/wan_i2v_workflow.json

# ------------------------------------------------------------------------------
# 7. Generate Launcher Scripts
# ------------------------------------------------------------------------------
echo "🛠️ [7/7] Generating launcher scripts..."

# Start script
cat << 'EOF' > ~/start_comfyui.sh
#!/usr/bin/env bash
tmux kill-session -t comfyui 2>/dev/null || true

# 1. Start Tailscale daemon in container mode
mkdir -p /var/run/tailscale /var/lib/tailscale
if ! pgrep -x "tailscaled" > /dev/null; then
    tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscaled.log 2>&1 &
    sleep 2
fi

# 2. Check if Tailscale needs login
TS_STATUS=$(tailscale --socket=/var/run/tailscale/tailscaled.sock status 2>&1 || true)
if [[ "$TS_STATUS" == *"Logged out"* ]] || [[ "$TS_STATUS" == *"NeedsLogin"* ]] || [[ -z "$TS_STATUS" ]]; then
    echo "=========================================================="
    echo "🔑 Click this link to authenticate Tailscale:"
    echo "=========================================================="
    tailscale --socket=/var/run/tailscale/tailscaled.sock up --accept-routes=true
fi

# 3. Start ComfyUI in background tmux
tmux new -d -s comfyui "bash -c 'source ~/ComfyUI/venv/bin/activate && cd ~/ComfyUI && python main.py --listen 0.0.0.0 --port 8188'"

# 4. Get Tailscale IP
TS_IP=$(tailscale --socket=/var/run/tailscale/tailscaled.sock ip -4 2>/dev/null || echo "127.0.0.1")

echo "=========================================================="
echo "🎉 ComfyUI is running securely on your Tailnet!"
echo "=========================================================="
echo "🔗 Access URL: http://${TS_IP}:8188"
echo ""
echo "💡 Instructions:"
echo " 1. Ensure Tailscale is connected on your local PC."
echo " 2. Open http://${TS_IP}:8188 in your browser."
echo " 3. Drag & drop ~/ComfyUI/workflows/wan_i2v_workflow.json"
echo ""
echo "To view ComfyUI logs:  tmux attach -t comfyui"
echo "To stop ComfyUI:       ~/stop_comfyui.sh"
echo "=========================================================="
EOF

# Stop script
cat << 'EOF' > ~/stop_comfyui.sh
#!/usr/bin/env bash
tmux kill-session -t comfyui 2>/dev/null || true
pkill -9 tailscaled 2>/dev/null || true
echo "🛑 ComfyUI and Tailscale stopped."
EOF

chmod +x ~/start_comfyui.sh ~/stop_comfyui.sh

echo ""
echo "=========================================================="
echo "✅ Setup Complete! Run ~/start_comfyui.sh to launch."
echo "=========================================================="