#!/usr/bin/env bash
set -e

# Function to print only lines with emojis
echo_emoji() {
    # Only print if line contains an emoji
    if [[ "$1" =~ [✅❌⚠️🐍🛠📦📄📥🐳🚀] ]]; then
        echo "$1"
    fi
}

# ---------------- HELP FUNCTION ----------------
usage() {
    echo_emoji "  🐍 Usage: $0 [options]"
    echo_emoji "  🐍 Options:"
    echo_emoji "  ✅ --package              Download macOS & Linux wheels and copy source code"
    echo_emoji "  ✅ --install-linux        Install dependencies and run script on Linux offline"
    echo_emoji "  ✅ --install-macos        Install dependencies and run script on macOS"
    echo_emoji "  ✅ --zip                  Zip the packaged folder (only valid with --package)"
    echo_emoji "  ✅ --script <file>        Specify Python script to run (default: auto-detect)"
    echo_emoji "  ✅ --help                 Show this help message"
    exit 0
}

# Example for one place where messages are shown
detect_python_version() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo_emoji "  ❌ python3 not found. Install Python 3 first."
        exit 1
    fi
    PYTHON_VERSION_DETECTED=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    echo_emoji "  🐍 Detected Python version: $PYTHON_VERSION_DETECTED"
}

# Example for packaging step
package() {
    detect_python_version
    echo_emoji "  🛠 Cleaning old build..."
    rm -rf "$PROJECT_NAME" 2>/dev/null || true
    mkdir -p "$PROJECT_NAME/macos" "$PROJECT_NAME/linux"

    echo_emoji "  📥 Downloading macOS wheels..."
    pip download -q -r requirements.txt -d "$PROJECT_NAME/macos"
    pip download -q pip setuptools wheel -d "$PROJECT_NAME/macos"

    echo_emoji "  🐳 Downloading Linux wheels via Docker..."
    if ! command -v docker >/dev/null 2>&1; then
        echo_emoji "  ❌ Docker not found. Install Docker Desktop."
        exit 1
    fi

    check_docker() { docker info >/dev/null 2>&1; }
    if ! check_docker; then
        echo_emoji "  ⚠️ Docker daemon not running. Starting Docker Desktop..."
        open -a Docker
        echo_emoji "  ⏳ Waiting for Docker to start..."
        TIMEOUT=60
        while ! check_docker; do
            sleep 2
            ((TIMEOUT--))
            if [ $TIMEOUT -le 0 ]; then
                echo_emoji "  ❌ Docker did not start. Start Docker manually and rerun."
                exit 1
            fi
        done
    fi

    docker run --rm -v "$(pwd)":/project python:$PYTHON_VERSION_DETECTED bash -c "
cd /project &&
pip install --upgrade pip -q &&
pip download -q -r requirements.txt -d $PROJECT_NAME/linux &&
pip download -q pip setuptools wheel -d $PROJECT_NAME/linux
"

    echo_emoji "  📄 Copying source code..."
    cp *.py "$PROJECT_NAME/" 2>/dev/null || true
    cp requirements.txt "$PROJECT_NAME/"
    cp -r src/ "$PROJECT_NAME/" 2>/dev/null || true

    echo_emoji "  ✅ Packaging complete!"
}

# ---------------- MAIN ----------------
PROJECT_NAME="packages"

# Example usage
package