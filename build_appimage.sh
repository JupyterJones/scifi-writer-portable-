#!/usr/bin/env bash
set -e

# ==============================================================================
# SciFi Vision Studio - AppImage Builder
# Builds a self-contained x86_64 AppImage with zero outside dependencies
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

APP_DIR="$ROOT_DIR/AppDir"
OUTPUT_APPIMAGE="$ROOT_DIR/SciFi-Vision-Studio-x86_64.AppImage"
DESKTOP_OUTPUT="$HOME/Desktop/SciFi-Vision-Studio-x86_64.AppImage"

echo "==> [1/6] Cleaning previous build artifacts..."
rm -rf "$APP_DIR"
rm -f "$OUTPUT_APPIMAGE"

echo "==> [2/6] Preparing AppDir directory structure..."
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

echo "==> [3/6] Staging application files (using hardlinks for 0-byte disk overhead)..."
# Core scripts and templates
cp "$ROOT_DIR/app.py" "$APP_DIR/"
cp "$ROOT_DIR/scifi_engine.py" "$APP_DIR/"
cp "$ROOT_DIR/apply_effects.py" "$APP_DIR/"
cp "$ROOT_DIR/template.md" "$APP_DIR/" 2>/dev/null || true
cp "$ROOT_DIR/TEMPLATEv2.md" "$APP_DIR/" 2>/dev/null || true
cp "$ROOT_DIR/TEMPLATEv3.md" "$APP_DIR/" 2>/dev/null || true

# Directories (hardlink structure to avoid duplicating multi-gigabyte models)
cp -al "$ROOT_DIR/templates" "$APP_DIR/"
cp -al "$ROOT_DIR/static" "$APP_DIR/"
cp -al "$ROOT_DIR/fonts" "$APP_DIR/"
cp -al "$ROOT_DIR/resources" "$APP_DIR/"
cp -al "$ROOT_DIR/mp3" "$APP_DIR/"
cp -al "$ROOT_DIR/models" "$APP_DIR/"
cp -al "$ROOT_DIR/venv" "$APP_DIR/"

# Starter assets directory structure
mkdir -p "$APP_DIR/assets"

# Bundle FFmpeg and FFprobe if available
if [ -x "/usr/local/bin/ffmpeg" ]; then
    echo "    -> Bundling FFmpeg & FFprobe into AppDir..."
    cp "/usr/local/bin/ffmpeg" "$APP_DIR/usr/bin/ffmpeg"
    cp "/usr/local/bin/ffprobe" "$APP_DIR/usr/bin/ffprobe"
elif command -v ffmpeg >/dev/null 2>&1; then
    cp "$(command -v ffmpeg)" "$APP_DIR/usr/bin/ffmpeg"
    cp "$(command -v ffprobe)" "$APP_DIR/usr/bin/ffprobe"
fi

# Ensure real Python ELF binary is present inside venv/bin
echo "    -> Embedding Python binary..."
rm -f "$APP_DIR/venv/bin/python3.12"
cp /usr/bin/python3.12 "$APP_DIR/venv/bin/python3.12"
ln -sf python3.12 "$APP_DIR/venv/bin/python3"
ln -sf python3.12 "$APP_DIR/venv/bin/python"

echo "==> [4/6] Creating AppRun and Desktop integration..."

# Generate 256x256 Icon
"$ROOT_DIR/venv/bin/python3" -c "
from PIL import Image
if (Image.open('$ROOT_DIR/digital_companion.jpg')):
    img = Image.open('$ROOT_DIR/digital_companion.jpg').resize((256, 256))
    img.save('$APP_DIR/scifi-vision-studio.png')
    img.save('$APP_DIR/usr/share/icons/hicolor/256x256/apps/scifi-vision-studio.png')
"

# Desktop file
cat << 'EOF' > "$APP_DIR/scifi-vision-studio.desktop"
[Desktop Entry]
Type=Application
Name=SciFi Vision Studio
GenericName=AI Video Studio
Comment=Produce speculative Sci-Fi videos with Ken Burns motion, Kokoro TTS narration, and local SD LCM
Exec=AppRun %F
Icon=scifi-vision-studio
Categories=AudioVideo;Video;Graphics;AudioVideoEditing;
Terminal=true
StartupNotify=true
EOF

cp "$APP_DIR/scifi-vision-studio.desktop" "$APP_DIR/usr/share/applications/scifi-vision-studio.desktop"

# AppRun launcher
cat << 'EOF' > "$APP_DIR/AppRun"
#!/usr/bin/env bash
SELF="$(readlink -f "$0")"
APPDIR="${SELF%/*}"

export APPDIR="${APPDIR}"
export PATH="${APPDIR}/venv/bin:${APPDIR}/usr/bin:${PATH}"
export PYTHONPATH="${APPDIR}/venv/lib/python3.12/site-packages:${PYTHONPATH}"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${APPDIR}/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

# Workspace selection: custom arg -> current directory (if writable) -> ~/Desktop/SciFi-Studio-Workspace
if [ -n "$1" ] && [ -d "$1" ] && [ -w "$1" ]; then
    export SCIFI_WORKSPACE="$(readlink -f "$1")"
elif [ -w "$(pwd)" ] && [ "$(pwd)" != "/" ] && [ "$(pwd)" != "/tmp" ]; then
    export SCIFI_WORKSPACE="$(pwd)"
else
    export SCIFI_WORKSPACE="$HOME/Desktop/SciFi-Studio-Workspace"
    mkdir -p "$SCIFI_WORKSPACE"
fi

cd "$SCIFI_WORKSPACE"

# Check local Ollama server
if pgrep -x "ollama" > /dev/null; then
    echo "✓ Ollama server active"
elif command -v ollama > /dev/null 2>&1; then
    echo "[*] Notice: Starting local Ollama service in background..."
    ollama serve > /dev/null 2>&1 &
    sleep 2
fi

PORT=5055
echo "=========================================================="
echo "   🚀 SCI-FI VISION STUDIO (STANDALONE APPIMAGE)          "
echo "   📁 Project Workspace: ${SCIFI_WORKSPACE}               "
echo "   🌐 Web Studio:        http://localhost:${PORT}         "
echo "=========================================================="

# Auto open browser
(
    sleep 2
    if command -v xdg-open > /dev/null 2>&1; then
        xdg-open "http://localhost:${PORT}" > /dev/null 2>&1
    elif command -v sensible-browser > /dev/null 2>&1; then
        sensible-browser "http://localhost:${PORT}" > /dev/null 2>&1
    fi
) &

# Launch web server via bundled Python
exec "${APPDIR}/venv/bin/python3" "${APPDIR}/app.py"
EOF

chmod +x "$APP_DIR/AppRun"

echo "==> [5/6] Packaging AppImage using appimagetool..."
APPIMAGETOOL=""
if [ -x "$HOME/Desktop/SCRIPTS/bin/appimagetool" ]; then
    APPIMAGETOOL="$HOME/Desktop/SCRIPTS/bin/appimagetool"
elif command -v appimagetool > /dev/null 2>&1; then
    APPIMAGETOOL="$(command -v appimagetool)"
elif [ -x "$HOME/.local/bin/appimagetool" ]; then
    APPIMAGETOOL="$HOME/.local/bin/appimagetool"
fi

if [ -z "$APPIMAGETOOL" ]; then
    echo "    -> appimagetool not found locally. Downloading standalone appimagetool..."
    mkdir -p /tmp/appimage_tools
    curl -L "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -o /tmp/appimage_tools/appimagetool
    chmod +x /tmp/appimage_tools/appimagetool
    APPIMAGETOOL="/tmp/appimage_tools/appimagetool"
fi

# Package into AppImage
ARCH=x86_64 "$APPIMAGETOOL" "$APP_DIR" "$OUTPUT_APPIMAGE"

# Clean up AppDir staging
rm -rf "$APP_DIR"

echo "==> [6/6] Finalizing AppImage..."
chmod +x "$OUTPUT_APPIMAGE"

# Optionally symlink to Desktop
ln -sf "$OUTPUT_APPIMAGE" "$DESKTOP_OUTPUT"

echo "=========================================================="
echo "  ✅ SUCCESS: AppImage built successfully!                "
echo "  📦 Output: $OUTPUT_APPIMAGE                             "
echo "  🖥️  Desktop: $DESKTOP_OUTPUT                            "
echo "=========================================================="
ls -lh "$OUTPUT_APPIMAGE"
