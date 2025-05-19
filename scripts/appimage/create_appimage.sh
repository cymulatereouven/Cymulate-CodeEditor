#!/bin/bash

# Exit on error
set -e

# Check platform
platform=$(uname)

if [[ "$platform" == "Darwin" ]]; then
    echo "Running on macOS. Note that the AppImage created will only work on Linux systems."
    if ! command -v docker &> /dev/null; then
        echo "Docker Desktop for Mac is not installed. Please install it from https://www.docker.com/products/docker-desktop"
        exit 1
    fi
elif [[ "$platform" == "Linux" ]]; then
    echo "Running on Linux. Proceeding with AppImage creation..."
else
    echo "This script is intended to run on macOS or Linux. Current platform: $platform"
    exit 1
fi

# Enable BuildKit
export DOCKER_BUILDKIT=1

BUILD_IMAGE_NAME="cymulateCodeEditor-appimage-builder"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

# Check and install Buildx if needed
if ! docker buildx version >/dev/null 2>&1; then
    echo "Installing Docker Buildx..."
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/buildx/releases/download/v0.13.1/buildx-v0.13.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
fi

# Download appimagetool if not present
if [ ! -f "appimagetool" ]; then
    echo "Downloading appimagetool..."
    curl -L -o appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x appimagetool
fi

# Delete any existing AppImage to acymulateCodeEditor bloating the build
rm -f cymulateCodeEditor-x86_64.AppImage

# Create build Dockerfile
echo "Creating build Dockerfile..."
cat > Dockerfile.build << 'EOF'
# syntax=docker/dockerfile:1
FROM ubuntu:20.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    libfuse2 \
    libglib2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxss1 \
    libxtst6 \
    libnss3 \
    libasound2 \
    libdrm2 \
    libgbm1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
EOF

# Create .dockerignore file
echo "Creating .dockerignore file..."
cat > .dockerignore << EOF
Dockerfile.build
.dockerignore
.git
.gitignore
.DS_Store
*~
*.swp
*.swo
*.tmp
*.bak
*.log
*.err
node_modules/
venv/
*.egg-info/
*.tox/
dist/
EOF

# Build Docker image without cache
echo "Building Docker image (no cache)..."
docker build --no-cache -t "$BUILD_IMAGE_NAME" -f Dockerfile.build .

# Create AppImage using local appimagetool
echo "Creating AppImage..."
docker run --rm --privileged -v "$(pwd):/app" "$BUILD_IMAGE_NAME" bash -c '
cd /app && \
rm -rf CymulateCodeEditor.AppDir && \
mkdir -p CymulateCodeEditor.AppDir/usr/bin CymulateCodeEditor.AppDir/usr/lib CymulateCodeEditor.AppDir/usr/share/applications && \
find . -maxdepth 1 ! -name CymulateCodeEditor.AppDir ! -name "." ! -name ".." -exec cp -r {} CymulateCodeEditor.AppDir/usr/bin/ \; && \
cp cymulateCodeEditor.png CymulateCodeEditor.AppDir/ && \
echo "[Desktop Entry]" > CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name=CymulateCodeEditor" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Comment=Open source AI code editor." >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "GenericName=Text Editor" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Exec=cymulateCodeEditor %F" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Icon=cymulateCodeEditor" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Type=Application" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "StartupNotify=false" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "StartupWMClass=CymulateCodeEditor" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Categories=TextEditor;Development;IDE;" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "MimeType=application/x-cymulateCodeEditor-workspace;" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Keywords=cymulateCodeEditor;" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Actions=new-empty-window;" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "[Desktop Action new-empty-window]" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name=New Empty Window" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[de]=Neues leeres Fenster" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[es]=Nueva ventana vacía" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[fr]=Nouvelle fenêtre vide" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[it]=Nuova finestra vuota" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[ja]=新しい空のウィンドウ" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[ko]=새 빈 창" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[ru]=Новое пустое окно" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[zh_CN]=新建空窗口" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Name[zh_TW]=開新空視窗" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Exec=cymulateCodeEditor --new-window %F" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
echo "Icon=cymulateCodeEditor" >> CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
chmod +x CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop && \
cp CymulateCodeEditor.AppDir/cymulateCodeEditor.desktop CymulateCodeEditor.AppDir/usr/share/applications/ && \
echo "[Desktop Entry]" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Name=CymulateCodeEditor - URL Handler" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Comment=Open source AI code editor." > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "GenericName=Text Editor" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Exec=cymulateCodeEditor --open-url %U" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Icon=cymulateCodeEditor" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Type=Application" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "NoDisplay=true" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "StartupNotify=true" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Categories=Utility;TextEditor;Development;IDE;" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "MimeType=x-scheme-handler/cymulateCodeEditor;" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
echo "Keywords=cymulateCodeEditor;" > CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
chmod +x CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop && \
cp CymulateCodeEditor.AppDir/cymulateCodeEditor-url-handler.desktop CymulateCodeEditor.AppDir/usr/share/applications/ && \
echo "#!/bin/bash" > CymulateCodeEditor.AppDir/AppRun && \
echo "HERE=\$(dirname \"\$(readlink -f \"\${0}\")\")" >> CymulateCodeEditor.AppDir/AppRun && \
echo "export PATH=\${HERE}/usr/bin:\${PATH}" >> CymulateCodeEditor.AppDir/AppRun && \
echo "export LD_LIBRARY_PATH=\${HERE}/usr/lib:\${LD_LIBRARY_PATH}" >> CymulateCodeEditor.AppDir/AppRun && \
echo "exec \${HERE}/usr/bin/cymulateCodeEditor --no-sandbox \"\$@\"" >> CymulateCodeEditor.AppDir/AppRun && \
chmod +x CymulateCodeEditor.AppDir/AppRun && \
chmod -R 755 CymulateCodeEditor.AppDir && \

# Strip unneeded symbols from the binary to reduce size
strip --strip-unneeded CymulateCodeEditor.AppDir/usr/bin/cymulateCodeEditor

ls -la CymulateCodeEditor.AppDir/ && \
ARCH=x86_64 ./appimagetool -n CymulateCodeEditor.AppDir cymulateCodeEditor-x86_64.AppImage
'

# Clean up
rm -rf CymulateCodeEditor.AppDir .dockerignore appimagetool

echo "AppImage creation complete! Your AppImage is: cymulateCodeEditor-x86_64.AppImage"
