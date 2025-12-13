# Security Onion 2.4 Automated Installation

This repository contains scripts and configuration files for automating Security Onion 2.4 installation in a distributed deployment.

## Deployment Architecture

```
Distributed Deployment (Airgap)

    ┌─────────────────────────────┐
    │   somanager `10.10.20.50`   │
    │     - Web Interface         │
    │     - Salt Master           │
    │     - Fleet Manager         │
    └─────────────┬───────────────┘
                  │
         ┌────────┴────────────────┬────────────...────────────┐
         │                         │                           │
┌────────▼──────────┐    ┌─────────▼─────────┐       ┌─────────▼─────────┐
│     sosearch      |    │     sosensor1     │  ...  │     sosensorN     │
│   `10.10.20.51`   │    │   `10.10.20.51`   │  ...  │   `10.10.20.5N`   │
└───────────────────┘    └───────────────────┘       └───────────────────┘
```

## Files Overview

| File | Description |
|------|-------------|
| `install_so.sh` | Main installation script with role flags |
| `so-setup-expect.exp` | Expect script for automating SO installer |
| `so_manager.conf` | Configuration for Manager node |
| `so_search.conf` | Configuration for Search node |
| `so_sensor.conf` | Configuration for Sensor nodes |

## Quick Start

### Step 1: Prepare the System

Boot from Security Onion ISO and complete initial OS installation.

### Step 2: Cancel Auto-Started Setup

**IMPORTANT:** When you first log in, `so-setup` will start automatically. You must cancel it first:

1. When `so-setup` wizard appears, select **No** or press `Ctrl+C`
2. Copy scripts to the system (USB, SCP, etc.)
3. Then run the automated installation

```bash
# Make scripts executable
chmod +x install_so.sh so-setup-expect.exp
```

### Step 3: Run Installation

```bash
# Install Manager node
sudo ./install_so.sh --manager

# Install Search node
sudo ./install_so.sh --search

# Install Sensor node
sudo ./install_so.sh --sensor
```

The script will prompt for:
- **Email/Username** - Admin account for web interface
- **Password** - Admin password (entered twice for confirmation)
- **Sensor Number** (sensor only) - 1-6, creates hostname sosensor1, sosensor2, etc.

## Configuration Files

### so_manager.conf
```bash
ROLE="MANAGER"
HOSTNAME="somanager"
STATIC_IP="10.10.20.50"
GATEWAY="10.10.20.254"
DNS_SERVER="10.10.20.253"
DNS_SEARCH_DOMAIN="asat.tht"
ANALYST_IP_RANGE="10.10.20.0/24"
```

### so_search.conf
```bash
ROLE="SEARCH"
HOSTNAME="sosearch"
STATIC_IP="10.10.20.51"
MANAGER_IP="10.10.20.50"
# ... same network settings
```

### so_sensor.conf
```bash
ROLE="SENSOR"
HOSTNAME_BASE="sosensor"    # Becomes sosensor1, sosensor2, etc.
SENSOR_IP_BASE="10.10.20.6" # Becomes 10.10.20.61, 10.10.20.62, etc.
MANAGER_IP="10.10.20.50"
# ... same network settings
```

## Installation Flow

The expect script automates these Security Onion installer steps:

| Step | Action | Value |
|------|--------|-------|
| 1 | Begin install | Yes → Install |
| 2 | Deployment architecture | Distributed |
| 3 | Deployment state | New (manager) / Existing (search/sensor) |
| 4 | Role | MANAGER / SEARCH / SENSOR |
| 5 | License | AGREE |
| 6 | Network | Airgap |
| 7 | Hostname | From config |
| 8 | Description | (blank) |
| 9 | NIC selection | Auto (manager/search) / Prompt (sensor) |
| 10 | IP assignment | STATIC |
| 11 | Network range | From config with /24 |
| 12 | Gateway | From config |
| 13 | DNS | From config (removes 8.8.8.8, 8.8.4.4) |
| 14 | DNS search domain | asat.tht |
| 15 | Docker IP range | Keep default (Yes) |
| 16 | Email/Username | Prompted at start |
| 17 | Password | Prompted at start |
| 18 | Web access method | IP |
| 19 | Analyst IP range | From config |
| 20 | Review | Yes |

## Network Configuration

| Role | Hostname | IP Address |
|------|----------|------------|
| Manager | somanager | 10.10.20.50 |
| Search | sosearch | 10.10.20.51 |
| Sensor 1 | sosensor1 | 10.10.20.61 |
| Sensor 2 | sosensor2 | 10.10.20.62 |
| Sensor 3 | sosensor3 | 10.10.20.63 |
| Sensor 4 | sosensor4 | 10.10.20.64 |
| Sensor 5 | sosensor5 | 10.10.20.65 |
| Sensor 6 | sosensor6 | 10.10.20.66 |

**Common Settings:**
- Network: 10.10.20.0/24
- Gateway: 10.10.20.254
- DNS: 10.10.20.253
- Search Domain: asat.tht

## Post-Installation

### Verify Installation
```bash
sudo so-status
```

### Access Web Interface
```
https://10.10.20.50
Username: (email you provided)
Password: (password you provided)
```

### Add Firewall Rules
```bash
sudo so-firewall includehost analyst 10.10.20.0/24
```

## Troubleshooting

### Check Logs
```bash
# Installation log
tail -f /var/log/so-automated-install.log

# SO logs
tail -f /opt/so/log/manager/*.log
```

### Service Status
```bash
sudo so-status
sudo docker ps -a
```

### Common Issues

1. **NIC not found**: Check `ip link show` and update config
2. **Services not starting**: Run `sudo so-restart`
3. **Cannot access web**: Run `sudo so-firewall includehost analyst <your-ip>`

## Documentation

- Official SO Docs: https://docs.securityonion.net/en/2.4/
- SO GitHub: https://github.com/Security-Onion-Solutions/securityonion
