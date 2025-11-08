#!/usr/bin/env bash
set -e

# ---------------- CONFIG ----------------
PROJECT_NAME="my_python_project"
ZIP_OUTPUT=false        # default: do not zip
SCRIPT_FILE=""          # empty means auto-detect
# ----------------------------------------

# ---------------- HELP FUNCTION ----------------
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --package              Download macOS & Linux wheels and copy source code"
    echo "  --install-linux        Install dependencies and run script on Linux offline"
    echo "  --install-macos        Install dependencies and run script on macOS"
    echo "  --zip                  Zip the packaged folder (only valid with --package)"
    echo "  --script <file>        Specify Python script to run (default: auto-detect)"
    echo "  --help                 Show this help message"
    exit 0
}

# ---------------- PARSE ARGUMENTS ----------------
DO_PACKAGE=false
DO_INSTALL_LINUX=false
DO_INSTALL_MACOS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --package) DO_PACKAGE=true ;;
        --install-linux) DO_INSTALL_LINUX=true ;;
        --install-macos) DO_INSTALL_MACOS=true ;;
        --zip) ZIP_OUTPUT=true ;;
        --script) SCRIPT_FILE="$2"; shift ;;
        --help) usage ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
    shift
done

# ---------------- AUTO-DETECT SCRIPT ----------------
auto_detect_script() {
    if [ -n "$SCRIPT_FILE" ]; then
        if [ ! -f "$SCRIPT_FILE" ]; then
            echo "❌ Specified script '$SCRIPT_FILE' does not exist."
            exit 1
        fi
        echo "🐍 Using user-specified script: $SCRIPT_FILE"
        return
    fi

    # Check for main.py first
    if [ -f "main.py" ]; then
        SCRIPT_FILE="main.py"
        echo "🐍 Auto-detected main script: $SCRIPT_FILE"
        return
    fi

    # Otherwise pick first .py file in project root
    PY_FILES=( *.py )
    if [ ${#PY_FILES[@]} -gt 0 ]; then
        SCRIPT_FILE="${PY_FILES[0]}"
        echo "🐍 Auto-detected main script: $SCRIPT_FILE"
        return
    fi

    echo "❌ No Python script found to run."
    exit 1
}

# ---------------- PYTHON VERSION DETECTION ----------------
detect_python_version() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ python3 not found. Install Python 3 first."
        exit 1
    fi
    PYTHON_VERSION_DETECTED=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    echo "🐍 Detected Python version: $PYTHON_VERSION_DETECTED"
}

# ---------------- PACKAGE FUNCTION ----------------
package() {
    detect_python_version
    auto_detect_script
    echo "🛠 Cleaning old build..."
    rm -rf "$PROJECT_NAME"
    mkdir -p "$PROJECT_NAME/packages/macos"
    mkdir -p "$PROJECT_NAME/packages/linux"

    echo "📥 Downloading macOS wheels..."
    pip download -r requirements.txt -d "$PROJECT_NAME/packages/macos"
    pip download pip setuptools wheel -d "$PROJECT_NAME/packages/macos"

    echo "🐳 Downloading Linux wheels via Docker..."
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not found. Install Docker Desktop."
        exit 1
    fi

    check_docker() { docker info >/dev/null 2>&1; }
    if ! check_docker; then
        echo "⚠️ Docker daemon not running. Starting Docker Desktop..."
        open -a Docker
        echo "⏳ Waiting for Docker to start..."
        TIMEOUT=60
        while ! check_docker; do
            sleep 2
            ((TIMEOUT--))
            if [ $TIMEOUT -le 0 ]; then
                echo "❌ Docker did not start. Start Docker manually and rerun."
                exit 1
            fi
        done
    fi

    docker run --rm -v "$(pwd)":/project python:$PYTHON_VERSION_DETECTED bash -c "
cd /project &&
pip install --upgrade pip &&
pip download -r requirements.txt -d $PROJECT_NAME/packages/linux &&
pip download pip setuptools wheel -d $PROJECT_NAME/packages/linux
"

    echo "📄 Copying source code..."
    cp *.py "$PROJECT_NAME/" 2>/dev/null || true
    cp requirements.txt "$PROJECT_NAME/"
    cp -r src/ "$PROJECT_NAME/" 2>/dev/null || true

    if [ "$ZIP_OUTPUT" = true ]; then
        ZIP_FILE="${PROJECT_NAME}.zip"
        echo "📦 Creating zip archive: $ZIP_FILE"
        zip -r "$ZIP_FILE" "$PROJECT_NAME"
    fi

    echo "✅ Packaging complete!"
}

# ---------------- INSTALL LINUX FUNCTION ----------------
install_linux() {
    auto_detect_script
    if [ ! -d "$PROJECT_NAME/packages/linux" ]; then
        echo "❌ Linux packages folder not found. Run --package first."
        exit 1
    fi

    VENV_DIR="$PROJECT_NAME/venv"
    echo "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR" --without-pip
    source "$VENV_DIR/bin/activate"

    # Auto-detect Python version inside venv
    PYTHON_VERSION_IN_VENV=$("$VENV_DIR/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    echo "🐍 Detected Python version in venv: $PYTHON_VERSION_IN_VENV"

    echo "🛠 Installing pip, setuptools, wheel from Linux packages..."
    "$VENV_DIR/bin/python" -m pip install --no-index --find-links "$PROJECT_NAME/packages/linux" pip setuptools wheel

    echo "📥 Installing project dependencies from Linux packages..."
    "$VENV_DIR/bin/pip" install --no-index --find-links "$PROJECT_NAME/packages/linux" -r "$PROJECT_NAME/requirements.txt"

    echo "🚀 Running $SCRIPT_FILE..."
    "$VENV_DIR/bin/python" "$PROJECT_NAME/$SCRIPT_FILE"
}

# ---------------- INSTALL MACOS FUNCTION ----------------
install_macos() {
    auto_detect_script
    if [ ! -d "$PROJECT_NAME/packages/macos" ]; then
        echo "❌ macOS packages folder not found. Run --package first."
        exit 1
    fi

    VENV_DIR="$PROJECT_NAME/venv"
    echo "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"

    echo "📥 Installing project dependencies from macOS packages..."
    "$VENV_DIR/bin/pip" install --no-index --find-links "$PROJECT_NAME/packages/macos" -r "$PROJECT_NAME/requirements.txt"

    echo "🚀 Running $SCRIPT_FILE..."
    "$VENV_DIR/bin/python" "$PROJECT_NAME/$SCRIPT_FILE"
}

# ---------------- MAIN ----------------
if [ "$DO_PACKAGE" = true ]; then
    package
fi

if [ "$DO_INSTALL_LINUX" = true ]; then
    install_linux
fi

if [ "$DO_INSTALL_MACOS" = true ]; then
    install_macos
fi

if [ "$DO_PACKAGE" = false ] && [ "$DO_INSTALL_LINUX" = false ] && [ "$DO_INSTALL_MACOS" = false ]; then
    usage
fi