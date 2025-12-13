#!/bin/bash

################################################################################
# Security Onion 2.4 Automated Installation Script
# Usage: ./install_so.sh --manager|--search|--sensor [--config /path/to/config]
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NODE_TYPE=""
CONFIG_FILE=""
LOG_FILE="/var/log/so-automated-install.log"

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

usage() {
    cat << EOF
Security Onion 2.4 Automated Installation Script

Usage: $0 --manager|--search|--sensor [OPTIONS]

Required:
    --manager       Install as Manager node (default config: so_manager_config.conf)
    --search        Install as Search node (default config: so_search_config.conf)
    --sensor        Install as Sensor/Forward node (default config: so_sensor_config.conf)

Options:
    --config FILE   Path to configuration file (optional, uses defaults above)
    --help          Show this help message

Configuration File Format:
    The config file should contain key=value pairs. See example config files:
    - so_manager_config.conf (Manager node)
    - so_search_config.conf (Search node)
    - so_sensor_config.conf (Sensor node)

Examples:
    # Use default config files
    $0 --manager
    $0 --search
    $0 --sensor
    
    # Use custom config files
    $0 --manager --config /path/to/my_manager_config.conf
    $0 --sensor --config ./custom_sensor.conf
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
            shift
            ;;
        --search)
            NODE_TYPE="search"
            shift
            ;;
        --sensor)
            NODE_TYPE="sensor"
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
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

# Set default config file if not specified
if [[ -z "$CONFIG_FILE" ]]; then
    case $NODE_TYPE in
        manager)
            CONFIG_FILE="./so_manager_config.conf"
            ;;
        search)
            CONFIG_FILE="./so_search_config.conf"
            ;;
        sensor)
            CONFIG_FILE="./so_sensor_config.conf"
            ;;
    esac
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Configuration file not found: $CONFIG_FILE"
fi

log "Starting Security Onion installation as ${NODE_TYPE} node"
log "Using configuration file: $CONFIG_FILE"

################################################################################
# Load Configuration
################################################################################

load_config() {
    log "Loading configuration from $CONFIG_FILE"
    
    # Source the config file
    source "$CONFIG_FILE"
    
    # Validate required variables based on node type
    case $NODE_TYPE in
        manager)
            REQUIRED_VARS="HOSTNAME MGMT_INTERFACE ADMIN_EMAIL ADMIN_PASSWORD"
            ;;
        search)
            REQUIRED_VARS="HOSTNAME MGMT_INTERFACE MANAGER_IP MANAGER_USER"
            ;;
        sensor)
            REQUIRED_VARS="HOSTNAME MGMT_INTERFACE MONITOR_INTERFACE MANAGER_IP MANAGER_USER"
            ;;
    esac
    
    for var in $REQUIRED_VARS; do
        if [[ -z "${!var}" ]]; then
            error "Required configuration variable missing: $var"
        fi
    done
    
    log "Configuration loaded successfully"
}

################################################################################
# Pre-installation Checks
################################################################################

pre_install_checks() {
    log "Running pre-installation checks..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
    
    # Check system requirements
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    CPU_CORES=$(nproc)
    
    warn "System Resources:"
    warn "  RAM: ${TOTAL_RAM}GB (Minimum: 16GB recommended)"
    warn "  CPU Cores: ${CPU_CORES} (Minimum: 4 cores recommended)"
    
    # Check network interfaces
    if ! ip link show "$MGMT_INTERFACE" &>/dev/null; then
        error "Management interface $MGMT_INTERFACE does not exist"
    fi
    
    if [[ "$NODE_TYPE" == "sensor" ]] && [[ -n "$MONITOR_INTERFACE" ]]; then
        if ! ip link show "$MONITOR_INTERFACE" &>/dev/null; then
            error "Monitor interface $MONITOR_INTERFACE does not exist"
        fi
    fi
    
    log "Pre-installation checks passed"
}

################################################################################
# Network Configuration
################################################################################

configure_network() {
    log "Configuring network..."
    
    # Set hostname
    hostnamectl set-hostname "$HOSTNAME"
    
    # Configure management interface
    if [[ "${ADDRESS_TYPE:-DHCP}" == "STATIC" ]]; then
        log "Configuring static IP: $STATIC_IP"
        # Create netplan or NetworkManager configuration
        # This depends on the base OS
        cat > /etc/netplan/01-so-mgmt.yaml << EOF
network:
  version: 2
  ethernets:
    $MGMT_INTERFACE:
      addresses:
        - $STATIC_IP/$NETMASK
      gateway4: $GATEWAY
      nameservers:
        addresses:
          - $DNS_SERVER
EOF
        netplan apply
    else
        log "Using DHCP for management interface"
    fi
    
    # Configure monitor interface (sensor only)
    if [[ "$NODE_TYPE" == "sensor" ]] && [[ -n "$MONITOR_INTERFACE" ]]; then
        log "Configuring monitor interface: $MONITOR_INTERFACE"
        ip link set "$MONITOR_INTERFACE" up
        ip link set "$MONITOR_INTERFACE" promisc on
    fi
    
    log "Network configuration complete"
}

################################################################################
# Security Onion Setup
################################################################################

run_so_setup() {
    log "Starting Security Onion setup..."
    
    # Create automated setup directory if it doesn't exist
    mkdir -p /root/so-automation
    
    # Generate automation file based on node type
    case $NODE_TYPE in
        manager)
            generate_manager_automation
            ;;
        search)
            generate_search_automation
            ;;
        sensor)
            generate_sensor_automation
            ;;
    esac
    
    # Run setup with automation
    log "Running so-setup with automation..."
    
    # Note: Security Onion 2.4 uses so-setup interactively
    # This is a framework - actual automation requires expect or similar
    warn "Security Onion 2.4 requires interactive setup"
    warn "Please run: sudo so-setup"
    warn "Or use the expect script wrapper for full automation"
}

################################################################################
# Generate Automation Configurations
################################################################################

generate_manager_automation() {
    log "Generating Manager node automation configuration"
    
    cat > /root/so-automation/manager.conf << EOF
# Manager Node Configuration
# Generated on $(date)

HOSTNAME=$HOSTNAME
MGMT_INTERFACE=$MGMT_INTERFACE
ADDRESS_TYPE=${ADDRESS_TYPE:-DHCP}
STATIC_IP=${STATIC_IP:-}
NETMASK=${NETMASK:-}
GATEWAY=${GATEWAY:-}
DNS_SERVER=${DNS_SERVER:-}

# Installation Type
INSTALL_TYPE=STANDALONE

# Admin Configuration
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# Components
ENABLE_WEB_INTERFACE=${ENABLE_WEB_INTERFACE:-yes}
ENABLE_MANAGER=${ENABLE_MANAGER:-yes}

# Resources
ELASTIC_MEMORY=${ELASTIC_MEMORY:-auto}
LOGSTASH_MEMORY=${LOGSTASH_MEMORY:-auto}

# Network Security
ALLOW_CIDR=${ALLOW_CIDR:-0.0.0.0/0}
EOF
    
    log "Manager automation configuration created at /root/so-automation/manager.conf"
}

generate_search_automation() {
    log "Generating Search node automation configuration"
    
    cat > /root/so-automation/search.conf << EOF
# Search Node Configuration
# Generated on $(date)

HOSTNAME=$HOSTNAME
MGMT_INTERFACE=$MGMT_INTERFACE
ADDRESS_TYPE=${ADDRESS_TYPE:-DHCP}
STATIC_IP=${STATIC_IP:-}
NETMASK=${NETMASK:-}
GATEWAY=${GATEWAY:-}
DNS_SERVER=${DNS_SERVER:-}

# Manager Connection
MANAGER_IP=$MANAGER_IP
MANAGER_USER=$MANAGER_USER

# Node Type
NODE_TYPE=SEARCHNODE

# Resources
ELASTIC_MEMORY=${ELASTIC_MEMORY:-auto}
LOGSTASH_MEMORY=${LOGSTASH_MEMORY:-auto}
EOF
    
    log "Search node automation configuration created at /root/so-automation/search.conf"
}

generate_sensor_automation() {
    log "Generating Sensor node automation configuration"
    
    cat > /root/so-automation/sensor.conf << EOF
# Sensor Node Configuration
# Generated on $(date)

HOSTNAME=$HOSTNAME
MGMT_INTERFACE=$MGMT_INTERFACE
MONITOR_INTERFACE=$MONITOR_INTERFACE
ADDRESS_TYPE=${ADDRESS_TYPE:-DHCP}
STATIC_IP=${STATIC_IP:-}
NETMASK=${NETMASK:-}
GATEWAY=${GATEWAY:-}
DNS_SERVER=${DNS_SERVER:-}

# Manager Connection
MANAGER_IP=$MANAGER_IP
MANAGER_USER=$MANAGER_USER

# Node Type
NODE_TYPE=SENSOR

# Sensor Configuration
HOME_NET=${HOME_NET:-192.168.0.0/16,10.0.0.0/8,172.16.0.0/12}
PCAP_SIZE=${PCAP_SIZE:-150}
SURICATA_THREADS=${SURICATA_THREADS:-auto}
ZEEK_THREADS=${ZEEK_THREADS:-auto}
EOF
    
    log "Sensor automation configuration created at /root/so-automation/sensor.conf"
}

################################################################################
# Post-Installation
################################################################################

post_install() {
    log "Running post-installation tasks..."
    
    # Firewall rules
    if [[ -n "${ALLOW_CIDR}" ]]; then
        log "Adding firewall rules for: $ALLOW_CIDR"
        so-firewall includehost analyst "$ALLOW_CIDR" 2>/dev/null || warn "Firewall command may need to be run manually"
    fi
    
    # Verify services
    log "Checking service status..."
    so-status || warn "Some services may not be running yet"
    
    log "Installation complete!"
    log "Access the web interface at: https://$(hostname -I | awk '{print $1}')"
    log "Username: $ADMIN_EMAIL (for manager)"
}

################################################################################
# Main Execution
################################################################################

main() {
    log "=================================="
    log "Security Onion Automated Install"
    log "Node Type: $NODE_TYPE"
    log "=================================="
    
    # Load and validate configuration
    load_config
    
    # Run pre-installation checks
    pre_install_checks
    
    # Configure network
    configure_network
    
    # Run Security Onion setup
    run_so_setup
    
    # Post-installation
    # post_install  # Uncomment after setup completes
    
    log "Script execution completed"
    log "Please review the logs at: $LOG_FILE"
    
    cat << EOF

${GREEN}Next Steps:${NC}
1. Review the generated configuration at /root/so-automation/${NODE_TYPE}.conf
2. Run the Security Onion setup wizard:
   ${YELLOW}sudo so-setup${NC}
3. For full automation, use the expect wrapper script
4. After setup completes, verify with:
   ${YELLOW}sudo so-status${NC}

EOF
}

# Run main function
main
