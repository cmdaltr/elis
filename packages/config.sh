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
    echo_emoji "  ✅ --install-linux        Install dependencies on Linux offline (venv by default)"
    echo_emoji "  ✅ --install-macos        Install dependencies and run script on macOS"
    echo_emoji "  ✅ --zip                  Zip the packaged folder (only valid with --package)"
    echo_emoji "  ✅ --script <file>        Specify Python script to run (default: auto-detect)"
    echo_emoji "  ✅ --venv <path>          Custom venv path (default: .venv on Linux)"
    echo_emoji "  ✅ --python <version>     Target Python version for Linux (e.g., 3.9, 3.11)"
    echo_emoji "  ✅ --reset                Clean all build artifacts and cache files"
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

    # Use target Python version for Linux if specified, otherwise use detected version
    if [ -n "$TARGET_PYTHON_VERSION" ]; then
        LINUX_PYTHON_VERSION="$TARGET_PYTHON_VERSION"
        echo_emoji "  🐍 Using target Python version for Linux: $LINUX_PYTHON_VERSION"
    else
        LINUX_PYTHON_VERSION="$PYTHON_VERSION_DETECTED"
        echo_emoji "  ⚠️ No --python specified. Using macOS version ($LINUX_PYTHON_VERSION) for Linux wheels."
        echo_emoji "  ⚠️ This may not match your Oracle Linux Python version!"
    fi

    echo_emoji "  🛠  Cleaning old build..."
    rm -rf "$PROJECT_NAME" 2>/dev/null || true
    mkdir -p "$PROJECT_NAME/macos" "$PROJECT_NAME/linux"

    echo_emoji "  📥 Downloading macOS wheels..."
    pip3 download -q -r requirements.txt -d "$PROJECT_NAME/macos"
    pip3 download -q pip setuptools wheel -d "$PROJECT_NAME/macos"

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

    docker run --platform linux/amd64 --rm -v "$(pwd)":/project python:$LINUX_PYTHON_VERSION bash -c "
cd /project &&
pip install --upgrade pip -q &&
pip download -q -r requirements.txt -d $PROJECT_NAME/linux &&
pip download -q pip setuptools wheel -d $PROJECT_NAME/linux
"

    echo_emoji "  📄 Copying source code..."
    cp elis.py "$PROJECT_NAME/" 2>/dev/null || true
    cp .env "$PROJECT_NAME/" 2>/dev/null || true
    cp requirements.txt "$PROJECT_NAME/"
    cp config.sh "$PROJECT_NAME/"
    cp -r src "$PROJECT_NAME/" 2>/dev/null || true
    cp -r suite "$PROJECT_NAME/" 2>/dev/null || true

    # Create empty logs directory for runtime (don't copy existing logs)
    mkdir -p "$PROJECT_NAME/logs"

    echo_emoji "  ✅ Packaging complete!"
}

# ---------------- INSTALL LINUX (OFFLINE) ----------------
install_linux() {
    echo_emoji "  🐳 Installing on Linux (offline mode)..."

    # Check if linux wheels directory exists (we're already in packages dir)
    if [ ! -d "linux" ]; then
        echo_emoji "  ❌ Linux packages not found. Are you in the packages directory?"
        exit 1
    fi

    # Check for python3
    if ! command -v python3 >/dev/null 2>&1; then
        echo_emoji "  ❌ python3 not found. Install Python 3 first."
        exit 1
    fi

    # Setup virtual environment (default on Linux)
    PYTHON_CMD="python3"

    # Set default venv path if not specified
    if [ -z "$VENV_PATH" ]; then
        VENV_PATH=".venv"
        echo_emoji "  🔧 Using default virtual environment at $VENV_PATH"
    fi

    echo_emoji "  🔧 Setting up virtual environment at $VENV_PATH..."

    if [ ! -d "$VENV_PATH" ]; then
        echo_emoji "  📦 Creating virtual environment (offline)..."
        python3 -m venv "$VENV_PATH"
    else
        echo_emoji "  ✅ Using existing virtual environment"
    fi

    # Use the venv's python
    PYTHON_CMD="$VENV_PATH/bin/python"

    if [ ! -f "$PYTHON_CMD" ]; then
        echo_emoji "  ❌ Virtual environment Python not found at $PYTHON_CMD"
        exit 1
    fi

    echo_emoji "  ✅ Virtual environment ready"

    # Check if pip is available, if not bootstrap it
    if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
        echo_emoji "  ⚠️ pip not found. Bootstrapping pip..."

        # Try using ensurepip (built into Python 3.4+)
        if $PYTHON_CMD -m ensurepip --version >/dev/null 2>&1; then
            echo_emoji "  🔧 Using ensurepip to bootstrap pip..."
            $PYTHON_CMD -m ensurepip --default-pip
        else
            # Manual bootstrap from wheel file
            echo_emoji "  🔧 Manually bootstrapping pip from wheel..."

            # Find the pip wheel
            PIP_WHEEL=$(ls linux/pip-*.whl 2>/dev/null | head -1)
            if [ -z "$PIP_WHEEL" ]; then
                echo_emoji "  ❌ pip wheel not found in linux/"
                exit 1
            fi

            # Extract pip wheel to temp directory and install
            TEMP_DIR=$(mktemp -d)
            unzip -q "$PIP_WHEEL" -d "$TEMP_DIR"
            PYTHONPATH="$TEMP_DIR" $PYTHON_CMD -m pip install --no-index --find-links="linux" pip
            rm -rf "$TEMP_DIR"
        fi

        # Verify pip is now available
        if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
            echo_emoji "  ❌ Failed to bootstrap pip. Check Python installation."
            exit 1
        fi

        echo_emoji "  ✅ pip bootstrapped successfully!"
    fi

    echo_emoji "  📦 Installing pip, setuptools, and wheel from local wheels..."
    $PYTHON_CMD -m pip install --no-index --find-links="linux" --upgrade pip setuptools wheel

    echo_emoji "  📦 Installing requirements from local wheels..."
    $PYTHON_CMD -m pip install --no-index --find-links="linux" -r requirements.txt

    echo_emoji "  ✅ Linux installation complete!"

    # Run the script if specified or auto-detected
    if [ -n "$PYTHON_SCRIPT" ]; then
        echo_emoji "  🚀 Running $PYTHON_SCRIPT..."
        $PYTHON_CMD "$PYTHON_SCRIPT"
    fi
}

# ---------------- INSTALL MACOS ----------------
install_macos() {
    echo_emoji "  🍎 Installing on macOS..."

    # Check if packages directory exists
    if [ ! -d "$PROJECT_NAME/macos" ]; then
        echo_emoji "  ❌ macOS packages not found. Run with --package first."
        exit 1
    fi

    # Check for python3
    if ! command -v python3 >/dev/null 2>&1; then
        echo_emoji "  ❌ python3 not found. Install Python 3 first."
        exit 1
    fi

    # Setup virtual environment if requested
    PYTHON_CMD="python3"
    if [ -n "$VENV_PATH" ]; then
        echo_emoji "  🔧 Setting up virtual environment at $VENV_PATH..."

        if [ ! -d "$VENV_PATH" ]; then
            echo_emoji "  📦 Creating virtual environment..."
            python3 -m venv "$VENV_PATH"
        else
            echo_emoji "  ✅ Using existing virtual environment"
        fi

        # Use the venv's python
        PYTHON_CMD="$VENV_PATH/bin/python"

        if [ ! -f "$PYTHON_CMD" ]; then
            echo_emoji "  ❌ Virtual environment Python not found at $PYTHON_CMD"
            exit 1
        fi

        echo_emoji "  ✅ Virtual environment ready"
    fi

    # Check if pip is available, if not bootstrap it
    if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
        echo_emoji "  ⚠️ pip not found. Bootstrapping pip..."

        # Try using ensurepip (built into Python 3.4+)
        if $PYTHON_CMD -m ensurepip --version >/dev/null 2>&1; then
            echo_emoji "  🔧 Using ensurepip to bootstrap pip..."
            $PYTHON_CMD -m ensurepip --default-pip
        else
            # Manual bootstrap from wheel file
            echo_emoji "  🔧 Manually bootstrapping pip from wheel..."

            # Find the pip wheel
            PIP_WHEEL=$(ls "$PROJECT_NAME/macos"/pip-*.whl 2>/dev/null | head -1)
            if [ -z "$PIP_WHEEL" ]; then
                echo_emoji "  ❌ pip wheel not found in $PROJECT_NAME/macos/"
                exit 1
            fi

            # Extract pip wheel to temp directory and install
            TEMP_DIR=$(mktemp -d)
            unzip -q "$PIP_WHEEL" -d "$TEMP_DIR"
            PYTHONPATH="$TEMP_DIR" $PYTHON_CMD -m pip install --no-index --find-links="$PROJECT_NAME/macos" pip
            rm -rf "$TEMP_DIR"
        fi

        # Verify pip is now available
        if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
            echo_emoji "  ❌ Failed to bootstrap pip. Check Python installation."
            exit 1
        fi

        echo_emoji "  ✅ pip bootstrapped successfully!"
    fi

    echo_emoji "  📦 Installing pip, setuptools, and wheel from local wheels..."
    $PYTHON_CMD -m pip install --no-index --find-links="$PROJECT_NAME/macos" --upgrade pip setuptools wheel

    echo_emoji "  📦 Installing requirements from local wheels..."
    $PYTHON_CMD -m pip install --no-index --find-links="$PROJECT_NAME/macos" -r "$PROJECT_NAME/requirements.txt"

    echo_emoji "  ✅ macOS installation complete!"

    # Run the script if specified or auto-detected
    if [ -n "$PYTHON_SCRIPT" ]; then
        echo_emoji "  🚀 Running $PYTHON_SCRIPT..."
        $PYTHON_CMD "$PROJECT_NAME/$PYTHON_SCRIPT"
    fi
}

# ---------------- AUTO-DETECT SCRIPT ----------------
detect_script() {
    # Look for common main script names in current directory
    for script in main.py app.py run.py elis.py; do
        if [ -f "$script" ]; then
            PYTHON_SCRIPT="$script"
            echo_emoji "  🔍 Auto-detected script: $PYTHON_SCRIPT"
            return
        fi
        # Also check in subdirectories with same name
        dir=$(echo "$script" | sed 's/\.py$//')
        if [ -f "$dir/$script" ]; then
            PYTHON_SCRIPT="$dir/$script"
            echo_emoji "  🔍 Auto-detected script: $PYTHON_SCRIPT"
            return
        fi
    done

    # If no common name found, look for any .py file in current directory
    py_files=(*.py)
    if [ -f "${py_files[0]}" ]; then
        PYTHON_SCRIPT="${py_files[0]}"
        echo_emoji "  🔍 Auto-detected script: $PYTHON_SCRIPT"
        return
    fi

    echo_emoji "  ⚠️ No Python script found. Skipping execution."
    PYTHON_SCRIPT=""
}

# ---------------- ZIP PACKAGE ----------------
zip_package() {
    if [ ! -d "$PROJECT_NAME" ]; then
        echo_emoji "  ❌ Package directory not found. Run with --package first."
        exit 1
    fi

    echo_emoji "  📦 Creating zip archive..."
    ZIP_FILE="${PROJECT_NAME}.zip"
    rm -f "$ZIP_FILE"
    zip -r -q "$ZIP_FILE" "$PROJECT_NAME"
    echo_emoji "  ✅ Created $ZIP_FILE"
}

# ---------------- RESET ----------------
reset_repository() {
    echo_emoji "  🧹 Resetting repository to clean state..."

    # Remove build artifacts
    echo_emoji "  🗑️ Removing build artifacts..."
    rm -rf "$PROJECT_NAME" "${PROJECT_NAME}.zip"

    # Remove virtual environments
    echo_emoji "  🗑️ Removing virtual environments..."
    rm -rf .venv

    # Remove Python cache files
    echo_emoji "  🗑️ Removing Python cache..."
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    find . -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

    # Remove macOS files
    echo_emoji "  🗑️ Removing macOS files..."
    find . -name ".DS_Store" -delete 2>/dev/null || true

    echo_emoji "  ✅ Repository reset complete!"
}

# ---------------- MAIN ----------------
PROJECT_NAME="packages"
PYTHON_SCRIPT=""
VENV_PATH=""
TARGET_PYTHON_VERSION=""
DO_PACKAGE=false
DO_INSTALL_LINUX=false
DO_INSTALL_MACOS=false
DO_ZIP=false
DO_RESET=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --package)
            DO_PACKAGE=true
            shift
            ;;
        --install-linux)
            DO_INSTALL_LINUX=true
            shift
            ;;
        --install-macos)
            DO_INSTALL_MACOS=true
            shift
            ;;
        --zip)
            DO_ZIP=true
            shift
            ;;
        --script)
            PYTHON_SCRIPT="$2"
            shift 2
            ;;
        --venv)
            VENV_PATH="$2"
            shift 2
            ;;
        --python)
            TARGET_PYTHON_VERSION="$2"
            shift 2
            ;;
        --reset)
            DO_RESET=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo_emoji "  ❌ Unknown option: $1"
            usage
            ;;
    esac
done

# Execute based on flags
if [ "$DO_RESET" = true ]; then
    reset_repository
elif [ "$DO_PACKAGE" = true ]; then
    package
    if [ "$DO_ZIP" = true ]; then
        zip_package
    fi
elif [ "$DO_INSTALL_LINUX" = true ]; then
    # Auto-detect script if not specified
    if [ -z "$PYTHON_SCRIPT" ]; then
        detect_script
    fi
    install_linux
elif [ "$DO_INSTALL_MACOS" = true ]; then
    # Auto-detect script if not specified
    if [ -z "$PYTHON_SCRIPT" ]; then
        detect_script
    fi
    install_macos
elif [ "$DO_ZIP" = true ]; then
    # Allow --zip to work standalone
    zip_package
else
    echo_emoji "  ❌ No action specified. Use --help for usage information."
    usage
fi