#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# This script MUST be run with sudo: sudo ./so-search.sh
###############################################################################

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use: sudo ./so-search.sh"
   exit 1
fi

echo "Getting started..."

###############################################################################
# Paths
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SO_SETUP_DIR="/home/tester/SecurityOnion/setup"
ORIG_WHIPTAIL="$SO_SETUP_DIR/so-whiptail"
BACKUP_WHIPTAIL="$SO_SETUP_DIR/so-whiptail.bak"
CUSTOM_WHIPTAIL="$SCRIPT_DIR/so-whiptail.search"

###############################################################################
# Sanity checks
###############################################################################

if [[ ! -f "$CUSTOM_WHIPTAIL" ]]; then
  echo "ERROR: custom so-whiptail.search not found in:"
  echo "  $SCRIPT_DIR"
  exit 1
fi

if [[ ! -f "$ORIG_WHIPTAIL" ]]; then
  echo "ERROR: original so-whiptail not found at:"
  echo "  $ORIG_WHIPTAIL"
  exit 1
fi

###############################################################################
# Backup original so-whiptail (once)
###############################################################################

if [[ ! -f "$BACKUP_WHIPTAIL" ]]; then
  echo "Backing up original so-whiptail..."
  cp "$ORIG_WHIPTAIL" "$BACKUP_WHIPTAIL"
else
  echo "Backup already exists, not overwriting."
fi

###############################################################################
# Replace so-whiptail
###############################################################################

echo "Installing custom so-whiptail..."
cp "$CUSTOM_WHIPTAIL" "$ORIG_WHIPTAIL"
chmod +x "$ORIG_WHIPTAIL"

###############################################################################
# Pre-accept Elastic License
###############################################################################

echo "Pre-accepting Elastic License..."
mkdir -p /opt/so/state
touch /opt/so/state/yeselastic.txt

###############################################################################
# Run installer
###############################################################################

echo "Launching Security Onion installer (ISO mode) for SEARCHNODE..."
exec "$SO_SETUP_DIR/so-setup" iso
