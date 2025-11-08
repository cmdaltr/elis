#!/usr/bin/env bash
set -e

PROJECT_DIR=$(dirname "$0")
VENV_DIR="$PROJECT_DIR/venv"

echo "📦 Creating virtual environment..."
python3 -m venv "$VENV_DIR" --without-pip || {
    echo "❌ Failed to create venv. Ensure python3 is installed."
    exit 1
}

source "$VENV_DIR/bin/activate"

# Use the bundled pip wheel to bootstrap pip
echo "🛠 Bootstrapping pip from local wheel files..."
BOOTSTRAP_WHEEL=$(ls "$PROJECT_DIR/packages"/pip-*.whl | head -n 1)
BOOTSTRAP_SETUPTOOLS=$(ls "$PROJECT_DIR/packages"/setuptools-*.whl | head -n 1)
BOOTSTRAP_WHEEL_TOOL=$(ls "$PROJECT_DIR/packages"/wheel-*.whl | head -n 1)

python3 -m ensurepip --default-pip >/dev/null 2>&1 || true

# Install pip, setuptools, wheel from wheels
"$VENV_DIR/bin/python" -m pip install --no-index --find-links "$PROJECT_DIR/packages" "$BOOTSTRAP_WHEEL" "$BOOTSTRAP_SETUPTOOLS" "$BOOTSTRAP_WHEEL_TOOL"

echo "📥 Installing project dependencies from local packages..."
"$VENV_DIR/bin/pip" install --no-index --find-links "$PROJECT_DIR/packages" -r "$PROJECT_DIR/requirements.txt"

echo "🚀 Running script..."
"$VENV_DIR/bin/python" "$PROJECT_DIR/script.py"