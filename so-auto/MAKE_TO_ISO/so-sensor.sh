#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# This script MUST be run with sudo: sudo ./so-sensor.sh [SENSOR_NUM]
#
# SENSOR_NUM determines the hostname and IP address:
#   so-sensor.sh 1  ->  so-sensor1  /  10.10.20.52
#   so-sensor.sh 2  ->  so-sensor2  /  10.10.20.53
#   so-sensor.sh 3  ->  so-sensor3  /  10.10.20.54
#   ...
#
# If no argument is provided, defaults to 1.
###############################################################################

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use: sudo ./so-sensor.sh [SENSOR_NUM]"
   exit 1
fi

###############################################################################
# Sensor number
###############################################################################

SENSOR_NUM="${1:-1}"
export SENSOR_NUM

if ! [[ "$SENSOR_NUM" =~ ^[0-9]+$ ]] || [[ "$SENSOR_NUM" -lt 1 ]]; then
  echo "ERROR: SENSOR_NUM must be a positive integer. Got: $SENSOR_NUM"
  exit 1
fi

echo "Getting started (sensor #${SENSOR_NUM}: so-sensor${SENSOR_NUM})..."

###############################################################################
# Paths
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SO_SETUP_DIR="/home/tester/SecurityOnion/setup"
ORIG_WHIPTAIL="$SO_SETUP_DIR/so-whiptail"
BACKUP_WHIPTAIL="$SO_SETUP_DIR/so-whiptail.bak"
CUSTOM_WHIPTAIL="$SCRIPT_DIR/so-whiptail.sensor"

###############################################################################
# Sanity checks
###############################################################################

if [[ ! -f "$CUSTOM_WHIPTAIL" ]]; then
  echo "ERROR: custom so-whiptail.sensor not found in:"
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

echo "Launching Security Onion installer (ISO mode) for SENSOR #${SENSOR_NUM}..."
exec "$SO_SETUP_DIR/so-setup" iso
