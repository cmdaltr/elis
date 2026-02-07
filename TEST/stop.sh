#!/bin/bash

# Stop ELIS Test Environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[+] Stopping Elasticsearch and Kibana..."
docker compose down

echo "[+] Services stopped."
echo ""
echo "To remove all data (volumes), run:"
echo "  docker compose down -v"
