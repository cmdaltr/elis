#!/usr/bin/env bash

# Stop on error
set -e

PROJECT_NAME="my_python_project"   # name of the output folder
PYTHON_VERSION="3.12"              # match the python version on the Linux box

echo "🔍 Checking for Docker installation..."

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed. Install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
  exit 1
fi

echo "🐳 Checking Docker daemon status..."

check_docker() {
  docker info >/dev/null 2>&1
}

if ! check_docker; then
  echo "⚠️  Docker daemon is not running. Attempting to start Docker Desktop..."
  open -a Docker

  echo "⏳ Waiting for Docker to start (up to 60 seconds)..."
  TIMEOUT=60
  while ! check_docker; do
    sleep 2
    ((TIMEOUT--))
    if [ $TIMEOUT -le 0 ]; then
      echo "❌ Docker did not start in time. Start Docker Desktop manually and rerun."
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

    echo '📥 Downloading Linux wheels