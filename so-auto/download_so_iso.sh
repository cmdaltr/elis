#!/bin/bash

ISO_URL="https://download.securityonion.net/file/securityonion/securityonion-2.4.200-20251216.iso"
ISO_FILE="securityonion-2.4.200-20251216.iso"
EXPECTED_HASH="8D3AC735873A2EA8527E16A6A08C34BD5018CBC0925AC4096E15A0C99F591D5F"

echo "Downloading Security Onion ISO..."
curl -L -O "$ISO_URL"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: Download failed - file not found"
    exit 1
fi

echo "Verifying SHA256 hash..."
ACTUAL_HASH=$(shasum -a 256 "$ISO_FILE" | awk '{print toupper($1)}')

if [ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]; then
    echo "Hash verification PASSED"
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $ACTUAL_HASH"
    exit 0
else
    echo "Hash verification FAILED"
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $ACTUAL_HASH"
    exit 1
fi
