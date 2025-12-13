#!/bin/bash

################################################################################
# Security Onion 2.4 Automated Installation Script
# Usage: ./install_so.sh --manager|--search|--sensor
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
NODE_TYPE=""
CONFIG_FILE=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
SENSOR_NUMBER=""

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

prompt() {
    echo -e "${CYAN}$1${NC}"
}

usage() {
    cat << EOF
Security Onion 2.4 Automated Installation Script

Usage: $0 --manager|--search|--sensor

Required (choose one):
    --manager   Install as Manager node (New Deployment)
                Config: so_manager.conf
    --search    Install as Search node (Existing Deployment)
                Config: so_search.conf
    --sensor    Install as Sensor node (Existing Deployment)
                Config: so_sensor.conf

Options:
    --help      Show this help message

The script will prompt for:
    - Email/Username (admin account)
    - Password (admin account)
    - Sensor number (1-6, sensor only)

Examples:
    $0 --manager
    $0 --search
    $0 --sensor
EOF
    exit 0
}

################################################################################
# Parse Arguments
################################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        --manager)
            NODE_TYPE="manager"
            CONFIG_FILE="${SCRIPT_DIR}/so_manager.conf"
            shift
            ;;
        --search)
            NODE_TYPE="search"
            CONFIG_FILE="${SCRIPT_DIR}/so_search.conf"
            shift
            ;;
        --sensor)
            NODE_TYPE="sensor"
            CONFIG_FILE="${SCRIPT_DIR}/so_sensor.conf"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

# Validate node type
if [[ -z "$NODE_TYPE" ]]; then
    error "Node type must be specified (--manager, --search, or --sensor)"
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Configuration file not found: $CONFIG_FILE"
fi

################################################################################
# Prompt for Credentials
################################################################################

echo ""
echo "========================================"
echo "Security Onion Automated Installation"
echo "Role: ${NODE_TYPE^^}"
echo "========================================"
echo ""

# Prompt for email/username
while [[ -z "$ADMIN_EMAIL" ]]; do
    prompt "Enter admin email/username: "
    read -r ADMIN_EMAIL
    if [[ -z "$ADMIN_EMAIL" ]]; then
        warn "Email cannot be empty"
    fi
done

# Prompt for password (hidden input)
while [[ -z "$ADMIN_PASSWORD" ]]; do
    prompt "Enter admin password: "
    read -rs ADMIN_PASSWORD
    echo ""
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        warn "Password cannot be empty"
        continue
    fi
    prompt "Confirm admin password: "
    read -rs ADMIN_PASSWORD_CONFIRM
    echo ""
    if [[ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]]; then
        warn "Passwords do not match"
        ADMIN_PASSWORD=""
    fi
done

# Prompt for sensor number (sensor only)
if [[ "$NODE_TYPE" == "sensor" ]]; then
    while [[ -z "$SENSOR_NUMBER" ]] || ! [[ "$SENSOR_NUMBER" =~ ^[1-6]$ ]]; do
        prompt "Enter sensor number (1-6): "
        read -r SENSOR_NUMBER
        if ! [[ "$SENSOR_NUMBER" =~ ^[1-6]$ ]]; then
            warn "Sensor number must be 1-6"
            SENSOR_NUMBER=""
        fi
    done
fi

################################################################################
# Load and Process Configuration
################################################################################

log "Loading configuration from $CONFIG_FILE"
source "$CONFIG_FILE"

# Process sensor-specific configuration
if [[ "$NODE_TYPE" == "sensor" ]]; then
    HOSTNAME="${HOSTNAME_BASE}${SENSOR_NUMBER}"
    STATIC_IP="${SENSOR_IP_BASE}${SENSOR_NUMBER}"
    log "Sensor hostname: $HOSTNAME"
    log "Sensor IP: $STATIC_IP"
fi

################################################################################
# Display Configuration Summary
################################################################################

echo ""
echo "========================================"
echo "Configuration Summary"
echo "========================================"
echo "Role:           ${NODE_TYPE^^}"
echo "Hostname:       $HOSTNAME"
echo "Static IP:      $STATIC_IP"
echo "Gateway:        $GATEWAY"
echo "DNS:            $DNS_SERVER"
echo "Search Domain:  $DNS_SEARCH_DOMAIN"
echo "Admin Email:    $ADMIN_EMAIL"
if [[ "$NODE_TYPE" != "manager" ]]; then
    echo "Manager IP:     $MANAGER_IP"
fi
echo "========================================"
echo ""

prompt "Proceed with installation? (yes/no): "
read -r CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    log "Installation cancelled"
    exit 0
fi

################################################################################
# Export Variables for Expect Script
################################################################################

export NODE_TYPE
export HOSTNAME
export STATIC_IP
export NETWORK_RANGE
export GATEWAY
export DNS_SERVER
export DNS_SEARCH_DOMAIN
export ADMIN_EMAIL
export ADMIN_PASSWORD
export ANALYST_IP_RANGE
export MANAGER_IP

################################################################################
# Run Expect Script
################################################################################

log "Starting Security Onion setup automation..."

EXPECT_SCRIPT="${SCRIPT_DIR}/so-setup-expect.exp"

if [[ ! -f "$EXPECT_SCRIPT" ]]; then
    error "Expect script not found: $EXPECT_SCRIPT"
fi

if ! command -v expect &> /dev/null; then
    error "expect command not found. Install with: apt install expect"
fi

log "Running expect script..."
expect "$EXPECT_SCRIPT"

log "Installation script completed"
