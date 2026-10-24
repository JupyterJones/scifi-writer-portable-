# 🚀 SciFi Vision Studio: Setup & Installation Guide

This repository contains the full engine, Web Studio UI, soundtrack library, fonts, and storyboard pipelines for **SciFi Vision Studio**.

Because GitHub enforces a **100 MB per-file limit**, large AI neural models (`.safetensors` and `.onnx`) and the Python virtual environment (`venv/`) are excluded from Git. A 1-click installer is provided to set them up automatically.

---

## ⚡ 1-Click Installation

### Prerequisites
* **Operating System**: Linux (Ubuntu 20.04+, Debian, Fedora, Arch, etc.)
* **Python**: Python 3.10, 3.11, or 3.12 (with `python3-venv` installed)
* **FFmpeg**: Required for video rendering (`sudo apt install ffmpeg`)
* **Ollama** *(Optional for AI script generation)*: [ollama.ai](https://ollama.ai) (e.g. `ollama pull scifi-writer:1`)

### Setup Instructions
Open a terminal inside the project directory and run:

```bash
chmod +x install.sh
./install.sh
```

### What `install.sh` Does Automatically:
1. **Creates Isolated Virtual Environment**: Builds `./venv` with exact package versions.
2. **Installs Core Dependencies**: Flask, Pillow, Requests, NumPy, and Kokoro TTS.
3. **Installs Lightweight CPU PyTorch & Diffusers**: Configured for multi-core CPU execution.
4. **Downloads AI Models Directly from Official Repositories**:
   * **Kokoro TTS Model** (`kokoro-v1.0.onnx`, 311 MB) -> `models/kokoro/`
   * **Kokoro Voice Weights** (`voices-v1.0.bin`, 25 MB) -> `models/kokoro/`
   * **Stable Diffusion LCM Checkpoint** (`dreamshaper_8LCM.safetensors`, 2.0 GB) -> `models/checkpoints/`
5. **Configures Runtime Folders & Permissions**: Prepares directories for temporary builds, uploads, and exports.

---

## 🎬 How to Launch the Web Studio

Once installed, start the local studio anytime with:

```bash
./start_studio.sh
```

Then open your browser to **http://localhost:5055**.

---

## 📦 How to Build the Standalone AppImage

Once `./install.sh` has finished, you can package the entire studio into a single portable `.AppImage` with zero outside dependencies:

```bash
./build_appimage.sh
```

* **Output**: `./SciFi-Vision-Studio-x86_64.AppImage` (and symlink on `~/Desktop`).
* **Portability**: The resulting AppImage bundles Python, PyTorch, Diffusers, Kokoro TTS, models, fonts, MP3s, and FFmpeg into an all-in-one executable that runs on any modern x86_64 Linux machine.

---

## 📂 Git & Repository Maintenance

The repository includes a configured `.gitignore` that keeps the repository lightweight and pushable to GitHub:
* Large AI model checkpoints (`*.safetensors`, `*.onnx`) are ignored.
* Virtual environment (`venv/`) and caches are ignored.
* Rendered `.mp4` video outputs are ignored.
* Standalone `.AppImage` binaries are ignored.

Run `git status` to verify that your working tree is clean and ready to commit!
