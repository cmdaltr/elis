#!/bin/bash

################################################################################
# Security Onion Screen-based Automation Script
# Uses screen's 'stuff' command to send keystrokes to whiptail dialogs
################################################################################

# Load configuration
source "$(dirname "$0")/install_so.conf" 2>/dev/null || {
    echo "Warning: No config file found, using environment variables"
}

# Configuration - override with environment variables if set
NODE_TYPE="${NODE_TYPE:-manager}"
HOSTNAME="${SO_HOSTNAME:-somanager}"
STATIC_IP="${STATIC_IP:-10.10.20.50}"
GATEWAY="${GATEWAY:-10.10.20.1}"
DNS_SERVER="${DNS_SERVER:-10.10.20.1}"
DNS_SEARCH_DOMAIN="${DNS_SEARCH_DOMAIN:-psychic.local}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@psychic.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Psychic.P@ssw0rd}"
ANALYST_IP_RANGE="${ANALYST_IP_RANGE:-10.10.20.0/24}"

SESSION_NAME="so-setup"

# Key codes
ENTER=$'\r'
TAB=$'\t'
DOWN=$'\033[B'

echo "========================================"
echo "Security Onion Automated Setup (Screen)"
echo "========================================"
echo "Node Type: $NODE_TYPE"
echo "Hostname: $HOSTNAME"
echo "Static IP: $STATIC_IP/24"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS_SERVER"
echo "========================================"

# Function to send keystrokes to screen session
send_keys() {
    screen -S "$SESSION_NAME" -X stuff "$1"
}

# Function to send and wait
send_and_wait() {
    send_keys "$1"
    sleep "${2:-2}"
}

# Kill any existing session
screen -S "$SESSION_NAME" -X quit 2>/dev/null
sleep 1

# Start installer in a detached screen session
echo ">>> Starting Security Onion setup in screen session..."
screen -dmS "$SESSION_NAME" sudo /home/tester/SecurityOnion/setup/so-setup iso

# Wait for installer to load
echo ">>> Waiting for installer to initialize..."
sleep 5

################################################################################
# MANAGER Installation Flow
################################################################################

if [ "$NODE_TYPE" = "manager" ]; then
    echo ">>> Step 1: Welcome - Enter for Yes"
    send_and_wait "$ENTER" 2

    echo ">>> Step 2: Install type - Enter for Install"
    send_and_wait "$ENTER" 2

    echo ">>> Step 3: Deployment - Down, Down, Down, Enter for Distributed"
    send_and_wait "$DOWN" 0.5
    send_and_wait "$DOWN" 0.5
    send_and_wait "$DOWN" 0.5
    send_and_wait "$ENTER" 2

    echo ">>> Step 4: New deployment - Enter"
    send_and_wait "$ENTER" 2

    echo ">>> Step 5: Role - Enter for Manager"
    send_and_wait "$ENTER" 2

    echo ">>> Step 6: License - typing AGREE"
    send_and_wait "AGREE$ENTER" 2

    echo ">>> Step 7: Network type - Down, Enter for Airgap"
    send_and_wait "$DOWN" 0.5
    send_and_wait "$ENTER" 2

    echo ">>> Step 8: Hostname - entering $HOSTNAME"
    # Ctrl+U to clear, then type hostname
    send_keys $'\025'
    sleep 0.5
    send_and_wait "$HOSTNAME$ENTER" 2

    echo ">>> Step 9: Description - leaving blank"
    send_and_wait "$ENTER" 2

    echo ">>> Step 10: NIC - Enter for default"
    send_and_wait "$ENTER" 2

    echo ">>> Step 11: IP assignment - Enter for Static"
    send_and_wait "$ENTER" 2

    echo ">>> Step 12: IP Address - entering $STATIC_IP/24"
    send_keys $'\025'
    sleep 0.5
    send_and_wait "${STATIC_IP}/24$ENTER" 2

    echo ">>> Step 13: Gateway - entering $GATEWAY"
    send_keys $'\025'
    sleep 0.5
    send_and_wait "$GATEWAY$ENTER" 2

    echo ">>> Step 14: DNS - removing defaults, adding $DNS_SERVER"
    send_and_wait "d" 0.5
    send_and_wait "d" 0.5
    send_and_wait "a" 0.5
    send_and_wait "$DNS_SERVER$ENTER" 0.5
    send_and_wait "$ENTER" 2

    echo ">>> Step 15: DNS Search Domain - entering $DNS_SEARCH_DOMAIN"
    send_keys $'\025'
    sleep 0.5
    send_and_wait "$DNS_SEARCH_DOMAIN$ENTER" 2

    echo ">>> Step 16: Docker defaults - Enter for Yes"
    send_and_wait "$ENTER" 2

    echo ">>> Step 17: Username/Email - entering $ADMIN_EMAIL"
    send_keys $'\025'
    sleep 0.5
    send_and_wait "$ADMIN_EMAIL$ENTER" 2

    echo ">>> Step 18: Password"
    send_and_wait "$ADMIN_PASSWORD$ENTER" 2

    echo ">>> Step 19: Web access method - Enter for IP"
    send_and_wait "$ENTER" 2

    echo ">>> Step 20: Web access confirmation - Enter"
    send_and_wait "$ENTER" 2

    echo ">>> Step 21: Analyst IP range - entering $ANALYST_IP_RANGE"
    send_keys $'\025'
    sleep 0.5
    send_and_wait "$ANALYST_IP_RANGE$ENTER" 2

    echo ">>> Step 22: Final confirmation - Tab, Enter"
    send_and_wait "$TAB" 0.5
    send_and_wait "$ENTER" 2

    echo ">>> Manager setup commands sent!"
fi

################################################################################
# Attach to session to monitor progress
################################################################################

echo ""
echo "========================================"
echo "Setup commands have been sent."
echo "Attaching to screen session to monitor..."
echo "Press Ctrl+A then D to detach"
echo "========================================"
echo ""

sleep 2
screen -r "$SESSION_NAME"
