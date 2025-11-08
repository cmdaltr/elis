#!/usr/bin/env bash

# Stop on error
set -e

PROJECT_NAME="my_python_project"   # name of the output folder
PYTHON_VERSION="3.12"              # match the python version on the Linux box

echo "🔍 Checking for Docker installation..."

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
  exit 1
fi

echo "🐳 Checking Docker daemon status..."

# Function to check if docker daemon is running
check_docker() {
  docker info >/dev/null 2>&1
}

if ! check_docker; then
  echo "⚠️  Docker daemon is not running. Attempting to start Docker Desktop..."

  # Try to start Docker Desktop (Mac only)
  open -a Docker

  echo "⏳ Waiting for Docker to start (this may take ~15–30 seconds)..."

  # Loop until docker responds or timeout (60s)
  TIMEOUT=60
  while ! check_docker; do
    sleep 2
    ((TIMEOUT--))
    if [ $TIMEOUT -le 0 ]; then
      echo "❌ Docker failed to start. Please start Docker Desktop manually and rerun the script."
      exit 1
    fi
  done
fi

echo "✅ Docker is running!"

echo "🛠️  Preparing output folder..."
rm -rf $PROJECT_NAME
mkdir -p $PROJECT_NAME/packages

echo "🚀 Launching temporary Linux environment via Docker..."
docker run --rm -it \
  -v "$(pwd)":/project \
  python:$PYTHON_VERSION \
  bash -c "
    cd /project &&
    pip install --upgrade pip &&
    mkdir -p $PROJECT_NAME/packages &&
    pip download -r requirements.txt -d $PROJECT_NAME/packages
  "

echo "📄 Copying source files..."
cp *.py $PROJECT_NAME/ 2>/dev/null || true
cp requirements.txt $PROJECT_NAME/
cp -r src/ $PROJECT_NAME/ 2>/dev/null || true

echo "✅ Finished!"
echo "➡️ Transfer '$PROJECT_NAME' to the Linux machine and run:"
echo ""
echo "python3 -m venv venv"
echo "source venv/bin/activate"
echo "pip install --no-index --find-links ./packages -r requirements.txt"
echo "python script.py"
echo ""