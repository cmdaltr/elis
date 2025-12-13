# Security Onion 2.4 Automated Installation

This repository contains scripts and configuration files for automating Security Onion 2.4 installation and configuration.

## Important Notes

⚠️ **Security Onion 2.4 Limitations**: 
- The official Security Onion 2.4 primarily uses an interactive setup wizard
- Full automation is limited compared to older versions
- These scripts provide a framework and automate what's possible
- Some manual interaction may still be required

## Files Overview

### Main Scripts

1. **install_so.sh** - Main installation orchestration script
2. **so-setup-expect.exp** - Expect wrapper for automating interactive prompts
3. **so_manager_config.conf** - Example configuration for Manager nodes
4. **so_search_config.conf** - Example configuration for Search nodes  
5. **so_sensor_config.conf** - Example configuration for Sensor nodes

## Prerequisites

### System Requirements

**Minimum Requirements:**
- CPU: 4 cores (x86-64 architecture)
- RAM: 16 GB
- Storage: 200 GB (100GB for / and 100GB for /nsm)
- Network: 2 NICs (1 for management, 1 for monitoring on sensors)

**Recommended for Production:**
- Manager: 8+ cores, 32+ GB RAM, 500+ GB storage
- Search: 8+ cores, 32+ GB RAM, 1+ TB storage
- Sensor: 8+ cores, 16+ GB RAM, 500+ GB storage (based on traffic)

### Software Prerequisites

```bash
# Install expect for automation
sudo apt-get update
sudo apt-get install -y expect

# Install Security Onion ISO or perform network installation
# See: https://docs.securityonion.net/en/2.4/installation.html
```

## Quick Start

### Step 1: Download Security Onion ISO

```bash
# Download the ISO
wget https://download.securityonion.net/file/securityonion/securityonion-2.4.170-20250812.iso

# Verify the ISO
wget https://raw.githubusercontent.com/Security-Onion-Solutions/securityonion/2.4/main/KEYS -O - | gpg --import -
wget https://github.com/Security-Onion-Solutions/securityonion/raw/2.4/main/sigs/securityonion-2.4.170-20250812.iso.sig
gpg --verify securityonion-2.4.170-20250812.iso.sig securityonion-2.4.170-20250812.iso
```

### Step 2: Boot from ISO

Boot your system from the Security Onion ISO and complete the initial OS installation.

### Step 3: Configure Installation

Edit the appropriate configuration file for your node type:

```bash
# For Manager node
cp so_manager_config.conf my_manager_config.conf
nano my_manager_config.conf

# For Search node
cp so_search_config.conf my_search_config.conf
nano my_search_config.conf

# For Sensor node
cp so_sensor_config.conf my_sensor_config.conf
nano my_sensor_config.conf
```

### Step 4: Run Installation

```bash
# Make scripts executable
chmod +x install_so.sh
chmod +x so-setup-expect.exp

# Run installation with default config files (recommended)
sudo ./install_so.sh --manager      # Uses so_manager_config.conf
sudo ./install_so.sh --search       # Uses so_search_config.conf
sudo ./install_so.sh --sensor       # Uses so_sensor_config.conf

# Or specify custom config files
sudo ./install_so.sh --manager --config /path/to/custom_config.conf
sudo ./install_so.sh --search --config my_search_config.conf
sudo ./install_so.sh --sensor --config my_sensor_config.conf
```

## Installation Methods

### Method 1: Semi-Automated (Recommended)

This method generates configuration files and prepares the system, but you run `so-setup` interactively:

```bash
# Prepare system and generate configs (uses default config files)
sudo ./install_so.sh --manager

# Or with a custom config file
sudo ./install_so.sh --manager --config my_custom_manager.conf

# Then manually run setup
sudo so-setup
```

### Method 2: Fully Automated (Experimental)

Use the expect wrapper for full automation:

```bash
# First run the preparation script
sudo ./install_so.sh --manager

# Then run the expect wrapper
sudo ./so-setup-expect.exp /root/so-automation/manager.conf
```

## Configuration Examples

### Manager Node Configuration

```bash
HOSTNAME="so-manager"
MGMT_INTERFACE="ens33"
ADDRESS_TYPE="STATIC"
STATIC_IP="192.168.1.100"
NETMASK="24"
GATEWAY="192.168.1.1"
DNS_SERVER="8.8.8.8"
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="SecurePassword123!"
INSTALL_TYPE="STANDALONE"
```

### Sensor Node Configuration

```bash
HOSTNAME="so-sensor-01"
MGMT_INTERFACE="ens33"
MONITOR_INTERFACE="ens34"
ADDRESS_TYPE="STATIC"
STATIC_IP="192.168.1.102"
MANAGER_IP="192.168.1.100"
MANAGER_USER="soremote"
HOME_NET="192.168.0.0/16,10.0.0.0/8"
```

## Deployment Architectures

### Standalone Deployment

Single node running all components:

```
┌─────────────────────┐
│   Manager Node      │
│  (All-in-One)       │
│                     │
│  - Web Interface    │
│  - Elasticsearch    │
│  - Logstash         │
│  - Suricata/Zeek    │
│  - PCAP Storage     │
└─────────────────────┘
```

### Distributed Deployment

```
┌─────────────────┐
│  Manager Node   │ ← Management & Web Interface
└────────┬────────┘
         │
    ┌────┴─────┬──────────────┬──────────┐
    │          │              │          │
┌───▼────┐ ┌──▼─────┐ ┌──────▼───┐ ┌───▼──────┐
│ Search │ │ Search │ │ Sensor 1 │ │ Sensor 2 │
│ Node 1 │ │ Node 2 │ │          │ │          │
└────────┘ └────────┘ └──────────┘ └──────────┘
```

## Post-Installation

### Verify Installation

```bash
# Check service status
sudo so-status

# View logs
sudo tail -f /opt/so/log/manager/*.log

# Check network configuration
ip addr show
```

### Access Web Interface

```bash
# Get your IP address
hostname -I

# Access via browser
https://<your-ip-address>

# Login with admin credentials from config
```

### Add Firewall Rules

```bash
# Allow specific IP or network
sudo so-firewall includehost analyst 192.168.1.0/24

# Or from the web interface:
# Administration → Configuration → firewall → hostgroups
```

### Join Additional Nodes

On the Manager, create a user for remote nodes:

```bash
# This is done during setup, but you can add more:
sudo so-user-add soremote
```

On each additional node (Search/Sensor):

```bash
# Configure with manager IP and credentials
sudo ./install_so.sh --sensor --config sensor_config.conf
```

## Troubleshooting

### Common Issues

**1. Network Interface Not Found**
```bash
# List available interfaces
ip link show

# Update your config file with correct interface names
```

**2. Services Not Starting**
```bash
# Check individual service logs
sudo docker ps -a
sudo so-elastic-status
sudo so-logstash-status

# Restart services
sudo so-restart
```

**3. Cannot Access Web Interface**
```bash
# Check firewall
sudo so-firewall list

# Add your IP
sudo so-firewall includehost analyst <your-ip>

# Verify web service
sudo docker ps | grep soc
```

**4. Disk Space Issues**
```bash
# Check disk usage
df -h

# Check /nsm partition
df -h /nsm

# Clean old data if needed
sudo so-elastic-indices-delete
```

### Logs Location

```
/opt/so/log/                    # Main log directory
/opt/so/log/manager/            # Manager logs
/var/log/so-automated-install.log  # Installation script log
```

## Advanced Configuration

### Resource Tuning

Edit your configuration file to adjust resources:

```bash
# Elasticsearch memory (in MB)
ELASTIC_MEMORY="8192"

# Logstash memory (in MB)
LOGSTASH_MEMORY="2048"

# Suricata threads
SURICATA_THREADS="8"

# Zeek threads
ZEEK_THREADS="8"
```

### Custom Rules

After installation, manage rules via the web interface:
- Navigate to **Detections** → **Rules**
- Import custom Suricata rules
- Enable/disable rules as needed

### Integration with SIEM

To forward logs to external SIEM:

```bash
# Edit Logstash output configuration
sudo nano /opt/so/saltstack/local/pillar/logstash/manager.sls

# Add your SIEM output configuration
# Restart Logstash
sudo so-logstash-restart
```

## Security Considerations

1. **Change Default Passwords**: Always use strong, unique passwords
2. **Network Segmentation**: Place monitor interfaces on dedicated network segments
3. **Firewall Rules**: Restrict access to management interface
4. **Regular Updates**: Keep Security Onion updated
5. **Backup Configuration**: Regularly backup `/nsm` and configuration files

## Backup and Recovery

### Backup Configuration

```bash
# Create backup
sudo so-elastic-backup

# Backup location
/nsm/backup/

# Backup configuration files
sudo tar -czf so-config-backup.tar.gz \
  /opt/so/saltstack/local/pillar/ \
  /etc/salt/
```

### Restore Configuration

```bash
# Restore from backup
sudo tar -xzf so-config-backup.tar.gz -C /

# Rerun setup if needed
sudo so-setup
```

## Documentation Links

- Official Documentation: https://docs.securityonion.net/en/2.4/
- GitHub Repository: https://github.com/Security-Onion-Solutions/securityonion
- Community Support: https://github.com/Security-Onion-Solutions/securityonion/discussions
- Training: https://securityonionsolutions.com/training

## Support

For issues specific to these automation scripts:
- Open an issue on your repository
- Review the installation log: `/var/log/so-automated-install.log`

For Security Onion issues:
- Official Support: https://github.com/Security-Onion-Solutions/securityonion/discussions
- Documentation: https://docs.securityonion.net/en/2.4/

## License

These automation scripts are provided as-is. Security Onion itself is licensed under GPL.

## Contributing

Contributions are welcome! Please:
1. Test your changes thoroughly
2. Update documentation
3. Submit pull requests with clear descriptions

## Changelog

### Version 1.0
- Initial release
- Support for Manager, Search, and Sensor nodes
- Configuration file templates
- Expect wrapper for automation
- Comprehensive documentation
