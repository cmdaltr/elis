#!/bin/bash

# ELIS Test Environment Setup Script
# This script starts Elasticsearch + Kibana and configures the kibana_system user

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables
source .env 2>/dev/null || true
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-changeme}"
KIBANA_PASSWORD="${KIBANA_PASSWORD:-changeme}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Start services
print_status "Starting Elasticsearch and Kibana..."
docker compose up -d elasticsearch

# Wait for Elasticsearch to be ready
print_status "Waiting for Elasticsearch to start (this may take a minute)..."
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s -k -u "elastic:${ELASTIC_PASSWORD}" "https://localhost:9200/_cluster/health" > /dev/null 2>&1; then
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
    echo -n "."
done
echo ""

if [ $attempt -eq $max_attempts ]; then
    print_error "Elasticsearch failed to start. Check logs with: docker compose logs elasticsearch"
    exit 1
fi

print_status "Elasticsearch is running!"

# Set kibana_system password
print_status "Setting kibana_system password..."
curl -s -k -X POST -u "elastic:${ELASTIC_PASSWORD}" \
    "https://localhost:9200/_security/user/kibana_system/_password" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"${KIBANA_PASSWORD}\"}" > /dev/null

# Start Kibana
print_status "Starting Kibana..."
docker compose up -d kibana

print_status "Waiting for Kibana to start..."
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s "http://localhost:5601/api/status" > /dev/null 2>&1; then
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
    echo -n "."
done
echo ""

if [ $attempt -eq $max_attempts ]; then
    print_warning "Kibana is still starting. Check status with: docker compose logs kibana"
else
    print_status "Kibana is running!"
fi

echo ""
print_status "============================================"
print_status "ELIS Test Environment Ready!"
print_status "============================================"
echo ""
echo "  Elasticsearch: https://localhost:9200"
echo "  Kibana:        http://localhost:5601"
echo ""
echo "  Username: elastic"
echo "  Password: ${ELASTIC_PASSWORD}"
echo ""
print_warning "Note: Elasticsearch uses a self-signed certificate."
print_warning "Use -k flag with curl or set verify_certs=False in Python."
echo ""
print_status "To stop:   docker compose down"
print_status "To reset:  docker compose down -v  (removes all data)"
