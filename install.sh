#!/usr/bin/env bash
set -e

# ==============================================================================
# SciFi Vision Studio: One-Click Environment & Model Installer
# Sets up virtual environment, downloads missing AI models, and prepares runtime
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=================================================================="
echo "   🚀 SCIFI VISION STUDIO — ONBOARDING & SETUP INSTALLER        "
echo "=================================================================="

# 1. System checks
echo "==> [1/5] Checking system prerequisites..."
if ! command -v python3 > /dev/null 2>&1; then
    echo "❌ Error: python3 is not installed. Please install Python 3 (3.10-3.12)."
    exit 1
fi

if ! command -v curl > /dev/null 2>&1 && ! command -v wget > /dev/null 2>&1; then
    echo "❌ Error: curl or wget is required to download model weights."
    exit 1
fi

if command -v ffmpeg > /dev/null 2>&1 || [ -x "/usr/local/bin/ffmpeg" ]; then
    echo "    ✓ FFmpeg detected for 1080p video compositing"
else
    echo "    ⚠️ Warning: FFmpeg not detected in PATH. Install via: sudo apt install ffmpeg"
fi

# 2. Virtual Environment Setup
echo "==> [2/5] Setting up isolated Python virtual environment (./venv)..."
if [ ! -f "$ROOT_DIR/venv/bin/python3" ]; then
    echo "    -> Creating clean virtual environment..."
    if ! python3 -m venv "$ROOT_DIR/venv" 2>/dev/null; then
        echo "❌ Error: Failed to create virtual environment."
        echo "   Please ensure python3-venv is installed:"
        echo "   sudo apt install python3-venv   (Ubuntu/Debian)"
        exit 1
    fi
    "$ROOT_DIR/venv/bin/pip" install --upgrade pip
    
    echo "    -> Installing core studio dependencies and Kokoro TTS..."
    "$ROOT_DIR/venv/bin/pip" install "flask>=3.0.0" "requests>=2.31.0" "pillow>=10.0.0" "numpy>=1.24.0" "kokoro-tts>=2.3.0"
    
    echo "    -> Installing lightweight CPU PyTorch & Diffusers..."
    "$ROOT_DIR/venv/bin/pip" install torch --index-url https://download.pytorch.org/whl/cpu
    "$ROOT_DIR/venv/bin/pip" install "diffusers>=0.25.0" "transformers>=4.36.0" "accelerate>=0.25.0"
else
    echo "    ✓ Existing virtual environment detected in ./venv"
fi

# 3. Download Kokoro TTS Models
echo "==> [3/5] Checking Kokoro TTS neural voice models..."
mkdir -p "$ROOT_DIR/models/kokoro"

KOKORO_ONNX="$ROOT_DIR/models/kokoro/kokoro-v1.0.onnx"
KOKORO_VOICES="$ROOT_DIR/models/kokoro/voices-v1.0.bin"

if [ ! -f "$KOKORO_ONNX" ]; then
    echo "    -> Downloading kokoro-v1.0.onnx (311 MB)..."
    curl -L "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx" -o "$KOKORO_ONNX"
else
    echo "    ✓ kokoro-v1.0.onnx already present"
fi

if [ ! -f "$KOKORO_VOICES" ]; then
    echo "    -> Downloading voices-v1.0.bin (25 MB)..."
    curl -L "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin" -o "$KOKORO_VOICES"
else
    echo "    ✓ voices-v1.0.bin already present"
fi

# 4. Download Stable Diffusion LCM Checkpoint
echo "==> [4/5] Checking Stable Diffusion LCM checkpoint..."
mkdir -p "$ROOT_DIR/models/checkpoints"

SD_CHECKPOINT=""
if ls "$ROOT_DIR/models/checkpoints/"*.safetensors >/dev/null 2>&1; then
    SD_CHECKPOINT="$(ls "$ROOT_DIR/models/checkpoints/"*.safetensors | head -n 1)"
    echo "    ✓ Existing SD checkpoint detected: $(basename "$SD_CHECKPOINT")"
else
    TARGET_CKPT="$ROOT_DIR/models/checkpoints/dreamshaper_8LCM.safetensors"
    echo "    -> Downloading dreamshaper_8LCM.safetensors (~2.0 GB) from Hugging Face..."
    echo "       Please wait, this provides 100% offline local image generation on CPU/GPU."
    curl -L "https://huggingface.co/Lykon/dreamshaper-8-lcm/resolve/main/DreamShaper8_LCM.safetensors" -o "$TARGET_CKPT"
    echo "    ✓ Checkpoint download complete"
fi

# 5. Finalizing Runtime Folders & Permissions
echo "==> [5/5] Finalizing runtime directories and permissions..."
mkdir -p "$ROOT_DIR/temp"
mkdir -p "$ROOT_DIR/exports"
mkdir -p "$ROOT_DIR/uploads"
mkdir -p "$ROOT_DIR/assets"

chmod +x "$ROOT_DIR/start_studio.sh" 2>/dev/null || true
chmod +x "$ROOT_DIR/build_appimage.sh" 2>/dev/null || true
chmod +x "$ROOT_DIR/build_video.py" 2>/dev/null || true
chmod +x "$ROOT_DIR/apply_effects.py" 2>/dev/null || true

echo "=================================================================="
echo "   ✅ INSTALLATION COMPLETE!                                     "
echo "=================================================================="
echo "To launch the Web Studio dashboard:"
echo "   ./start_studio.sh"
echo ""
echo "To build a standalone portable AppImage:"
echo "   ./build_appimage.sh"
echo "=================================================================="
