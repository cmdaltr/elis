#!/usr/bin/env bash
set -e

PROJECT_DIR=$(dirname "$0")

echo "📦 Setting up virtual environment..."
python3 -m venv "$PROJECT_DIR/venv" --without-pip || {
    echo "❌ Failed to create venv — ensure python3 is installed."
    exit 1
}

source "$PROJECT_DIR/venv/bin/activate"

echo "🛠 Installing pip, setuptools, and wheel from local packages..."
python -m pip install --no-index --find-links "$PROJECT_DIR/packages" pip setuptools wheel

echo "📥 Installing project dependencies from local packages..."
pip install --no-index --find-links "$PROJECT_DIR/packages" -r "$PROJECT_DIR/requirements.txt"

echo "🚀 Running script..."
python "$PROJECT_DIR/script.py"