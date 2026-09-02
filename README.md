# 🎬 I2V: Automated ComfyUI + Wan 2.1 (14B FP8) Video Generation

One-click setup script to deploy **ComfyUI** with **Wan 2.1 14B Image-to-Video** and secure **Tailscale VPN** on any GPU VPS (QuickPod, RunPod, Vast.ai, Lambda Labs).

---

## ⚡ Quick Start (One Command)

On your fresh GPU VPS (Ubuntu/Debian), run:

```bash
git clone https://github.com/Malay-Max/I2V.git && cd I2V && chmod +x setup.sh && ./setup.sh
```

The script will automatically:
1. Install all system dependencies (`git`, `python3-venv`, `libgl1`, `ffmpeg`, `tmux`, `curl`, `tailscale`).
2. Install **ComfyUI** and **PyTorch with CUDA 12.6**.
3. Install required custom node packs:
   - `ComfyUI-Manager`
   - `ComfyUI-WanVideoWrapper`
   - `ComfyUI-KJNodes`
   - `ComfyUI-VideoHelperSuite`
4. Download all verified model weights:
   - **Diffusion Model**: Wan 2.1 14B I2V (FP8 Scaled) (~15.5 GB)
   - **Text Encoder**: UMT5-XXL (FP8) (~5.5 GB)
   - **VAE**: Wan 2.1 VAE (~250 MB)
   - **CLIP Vision**: Official `clip_vision_h.safetensors` (~1.26 GB)
   - **Speedup LoRA**: Lightx2v Step Distillation LoRA (~1.5 GB)
5. Configure the `wan_i2v_workflow.json` template.
6. Generate `start_comfyui.sh` and `stop_comfyui.sh` management scripts.

---

## 🚀 Launching & Accessing ComfyUI

### 1. Start ComfyUI & Tailscale
```bash
~/start_comfyui.sh
```

- If Tailscale is not logged in, it will print an authentication link. Click it to log in with your account.
- It will display your private Tailscale URL:
  ```text
  🎉 ComfyUI is running securely on your Tailnet!
  🔗 Access URL: http://100.x.y.z:8188
  ```

### 2. Open in Browser
Ensure Tailscale is connected on your local PC/Mac, then open **`http://100.x.y.z:8188`**.

### 3. Stop ComfyUI
```bash
~/stop_comfyui.sh
```

### 4. View Live Logs
```bash
tmux attach -t comfyui
# Press Ctrl+B then D to detach safely
```

---

## 🎨 Recommended Generation Settings

### Aspect Ratio & Dimensions (Resize Image v2 Node)
* **Automatic (No crop)**: Set `keep_proportion` to **`resize`** and `divisible_by` to **`16`**.
* **Widescreen / Landscape (16:9)**: `832 × 480`
* **Portrait / Phone / TikTok (9:16)**: `480 × 832`
* **HD Landscape (720p model)**: `1280 × 720`

### Duration / Frame Count
Wan 2.1 frame counts must follow `4n + 1`:
* **81 frames** = ~5.0s (at 16 fps) / ~3.4s (at 24 fps)
* **121 frames** = ~7.5s (at 16 fps) / ~5.0s (at 24 fps)
* **161 frames** = ~10.0s (at 16 fps) / ~6.7s (at 24 fps)

---

## 🧠 Prompting Guide

Focus on **motion, physics, and camera direction** rather than describing the subject appearance:

> **Formula:** `[Action / Subject Movement] + [Hair / Cloth / Environmental Physics] + [Camera Motion] + [Lighting / Pacing Quality]`

**Example:**
> *"The woman slowly turns her head to face the camera, blinking gently with a subtle smile. A soft breeze catches her hair, making it flutter across her shoulder. Static tripod camera shot, soft cinematic lighting, smooth natural motion, 24fps."*