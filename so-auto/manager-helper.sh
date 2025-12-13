#!/bin/bash

################################################################################
# Security Onion Manager Post-Setup Helper
# Run this on the manager after initial setup to prepare for distributed deployment
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

usage() {
    cat << EOF
Security Onion Manager Post-Setup Helper

This script helps configure a manager node for distributed deployment.

Usage: $0 [OPTIONS]

Options:
    --create-remote-user    Create soremote user for node connections
    --add-firewall-rules    Add firewall rules for sensor/search nodes
    --generate-join-script  Generate join scripts for additional nodes
    --all                   Run all setup tasks
    --help                  Show this help message

Examples:
    $0 --create-remote-user
    $0 --add-firewall-rules
    $0 --all
EOF
    exit 0
}

################################################################################
# Create Remote User
################################################################################

create_remote_user() {
    log "Creating soremote user for node connections..."
    
    read -p "Enter password for soremote user: " -s SOREMOTE_PASSWORD
    echo
    read -p "Confirm password: " -s SOREMOTE_PASSWORD_CONFIRM
    echo
    
    if [[ "$SOREMOTE_PASSWORD" != "$SOREMOTE_PASSWORD_CONFIRM" ]]; then
        error "Passwords do not match"
    fi
    
    # Create user using so-user-add
    if command -v so-user-add &> /dev/null; then
        echo "$SOREMOTE_PASSWORD" | sudo so-user-add soremote
        log "soremote user created successfully"
    else
        warn "so-user-add command not found. You may need to create the user manually."
        log "After setup completes, run: sudo so-user-add soremote"
    fi
}

################################################################################
# Add Firewall Rules
################################################################################

add_firewall_rules() {
    log "Configuring firewall rules..."
    
    echo "Enter IP addresses or networks that should be allowed (CIDR notation)"
    echo "Examples: 192.168.1.100, 192.168.1.0/24, 10.0.0.0/8"
    echo "Enter one per line, empty line to finish:"
    
    ADDRESSES=()
    while true; do
        read -p "Address/Network: " ADDRESS
        if [[ -z "$ADDRESS" ]]; then
            break
        fi
        ADDRESSES+=("$ADDRESS")
    done
    
    for addr in "${ADDRESSES[@]}"; do
        log "Adding firewall rule for: $addr"
        sudo so-firewall includehost analyst "$addr" || warn "Failed to add rule for $addr"
    done
    
    log "Firewall rules updated"
    log "To view current rules: sudo so-firewall list"
}

################################################################################
# Generate Join Scripts
################################################################################

generate_join_scripts() {
    log "Generating node join scripts..."
    
    MANAGER_IP=$(hostname -I | awk '{print $1}')
    
    # Get manager hostname
    MANAGER_HOSTNAME=$(hostname)
    
    mkdir -p /tmp/so-join-scripts
    
    # Generate sensor join script
    cat > /tmp/so-join-scripts/join-sensor.sh << 'EOF'
#!/bin/bash

# Security Onion Sensor Join Script
# Run this script on a sensor node to join it to the manager

MANAGER_IP="MANAGER_IP_PLACEHOLDER"
MANAGER_USER="soremote"

echo "This script will configure this node as a Security Onion sensor"
echo "Manager IP: $MANAGER_IP"
echo ""

read -p "Enter sensor hostname: " SENSOR_HOSTNAME
read -p "Enter management interface (e.g., ens33): " MGMT_INTERFACE
read -p "Enter monitor interface (e.g., ens34): " MONITOR_INTERFACE
read -p "Enter HOME_NET (e.g., 192.168.0.0/16,10.0.0.0/8): " HOME_NET

echo "Creating configuration file..."
cat > /tmp/sensor-config.conf << CONFEOF
HOSTNAME=$SENSOR_HOSTNAME
MGMT_INTERFACE=$MGMT_INTERFACE
MONITOR_INTERFACE=$MONITOR_INTERFACE
MANAGER_IP=$MANAGER_IP
MANAGER_USER=$MANAGER_USER
NODE_TYPE=SENSOR
HOME_NET=$HOME_NET
ADDRESS_TYPE=DHCP
CONFEOF

echo "Configuration created. Now run Security Onion setup:"
echo "  sudo so-setup"
echo ""
echo "When prompted, use these values:"
echo "  - Node Type: SENSOR (Forward Node)"
echo "  - Manager IP: $MANAGER_IP"
echo "  - Manager User: $MANAGER_USER"
echo "  - Hostname: $SENSOR_HOSTNAME"
echo "  - Management Interface: $MGMT_INTERFACE"
echo "  - Monitor Interface: $MONITOR_INTERFACE"
echo "  - HOME_NET: $HOME_NET"
EOF

    # Replace placeholder
    sed -i "s/MANAGER_IP_PLACEHOLDER/$MANAGER_IP/g" /tmp/so-join-scripts/join-sensor.sh
    chmod +x /tmp/so-join-scripts/join-sensor.sh
    
    # Generate search node join script
    cat > /tmp/so-join-scripts/join-search.sh << 'EOF'
#!/bin/bash

# Security Onion Search Node Join Script
# Run this script on a search node to join it to the manager

MANAGER_IP="MANAGER_IP_PLACEHOLDER"
MANAGER_USER="soremote"

echo "This script will configure this node as a Security Onion search node"
echo "Manager IP: $MANAGER_IP"
echo ""

read -p "Enter search node hostname: " SEARCH_HOSTNAME
read -p "Enter management interface (e.g., ens33): " MGMT_INTERFACE

echo "Creating configuration file..."
cat > /tmp/search-config.conf << CONFEOF
HOSTNAME=$SEARCH_HOSTNAME
MGMT_INTERFACE=$MGMT_INTERFACE
MANAGER_IP=$MANAGER_IP
MANAGER_USER=$MANAGER_USER
NODE_TYPE=SEARCHNODE
ADDRESS_TYPE=DHCP
CONFEOF

echo "Configuration created. Now run Security Onion setup:"
echo "  sudo so-setup"
echo ""
echo "When prompted, use these values:"
echo "  - Node Type: SEARCHNODE (Search Node)"
echo "  - Manager IP: $MANAGER_IP"
echo "  - Manager User: $MANAGER_USER"
echo "  - Hostname: $SEARCH_HOSTNAME"
echo "  - Management Interface: $MGMT_INTERFACE"
EOF

    sed -i "s/MANAGER_IP_PLACEHOLDER/$MANAGER_IP/g" /tmp/so-join-scripts/join-search.sh
    chmod +x /tmp/so-join-scripts/join-search.sh
    
    log "Join scripts generated in /tmp/so-join-scripts/"
    log "Copy these scripts to your sensor/search nodes and run them"
    echo ""
    echo "Files created:"
    echo "  - /tmp/so-join-scripts/join-sensor.sh"
    echo "  - /tmp/so-join-scripts/join-search.sh"
}

################################################################################
# Status Check
################################################################################

check_status() {
    log "Checking Security Onion status..."
    
    echo ""
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I | awk '{print $1}')"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo ""
    
    if command -v so-status &> /dev/null; then
        echo "=== Service Status ==="
        sudo so-status
        echo ""
    fi
    
    if command -v docker &> /dev/null; then
        echo "=== Docker Containers ==="
        sudo docker ps --format "table {{.Names}}\t{{.Status}}"
        echo ""
    fi
    
    echo "=== Disk Usage ==="
    df -h / /nsm 2>/dev/null || df -h /
    echo ""
    
    echo "=== Memory Usage ==="
    free -h
    echo ""
    
    log "Web Interface: https://$(hostname -I | awk '{print $1}')"
}

################################################################################
# Display Manager Information
################################################################################

display_info() {
    MANAGER_IP=$(hostname -I | awk '{print $1}')
    
    cat << EOF

${GREEN}╔══════════════════════════════════════════════════════════════════╗
║           Security Onion Manager Configuration Info              ║
╚══════════════════════════════════════════════════════════════════╝${NC}

${YELLOW}Manager Access:${NC}
  Web Interface: https://$MANAGER_IP
  SSH: ssh $(whoami)@$MANAGER_IP

${YELLOW}For Distributed Deployment:${NC}
  1. Create soremote user (if not done):
     ${GREEN}sudo so-user-add soremote${NC}
  
  2. Add firewall rules for your nodes:
     ${GREEN}sudo so-firewall includehost analyst <node-ip>${NC}
  
  3. On each node, run setup and provide:
     - Manager IP: $MANAGER_IP
     - Manager User: soremote
     - Node Type: SENSOR or SEARCHNODE

${YELLOW}Useful Commands:${NC}
  Check status:     ${GREEN}sudo so-status${NC}
  View logs:        ${GREEN}sudo tail -f /opt/so/log/manager/*.log${NC}
  Restart services: ${GREEN}sudo so-restart${NC}
  Add user:         ${GREEN}sudo so-user-add <username>${NC}
  Firewall rules:   ${GREEN}sudo so-firewall list${NC}

${YELLOW}Documentation:${NC}
  https://docs.securityonion.net/en/2.4/

EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    case "$1" in
        --create-remote-user)
            create_remote_user
            ;;
        --add-firewall-rules)
            add_firewall_rules
            ;;
        --generate-join-script)
            generate_join_scripts
            ;;
        --status)
            check_status
            ;;
        --all)
            create_remote_user
            add_firewall_rules
            generate_join_scripts
            check_status
            display_info
            ;;
        --info)
            display_info
            ;;
        --help)
            usage
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information."
            ;;
    esac
}

# Check if running as root
if [[ $EUID -ne 0 ]] && [[ "$1" != "--help" ]] && [[ "$1" != "--info" ]]; then
    error "This script must be run as root (use sudo)"
fi

if [[ $# -eq 0 ]]; then
    usage
fi

main "$@"
