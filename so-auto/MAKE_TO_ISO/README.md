# MAKE_TO_ISO - Unattended Security Onion Setup Scripts

Automated installation scripts that replace the interactive `so-whiptail` dialogs with hardcoded values, enabling unattended Security Onion deployment via ISO.

## Files

| Script | Whiptail Override | Role |
|---|---|---|
| `so-manager.sh` | `so-whiptail.manager` | Manager (new deployment) |
| `so-search.sh` | `so-whiptail.search` | Search node (joins existing grid) |
| `so-sensor.sh` | `so-whiptail.sensor` | Sensor (joins existing grid) |

## How It Works

Each launcher script (`so-*.sh`):

1. Backs up the original `so-whiptail` in the SO setup directory
2. Replaces it with the role-specific override file
3. Pre-accepts the Elastic License
4. Runs `so-setup iso`

The override files contain the original SO whiptail functions followed by redefined versions at the bottom that return hardcoded values instead of showing interactive dialogs.

## Usage

All scripts must be run as root on the target Security Onion VM.

```bash
# Manager
sudo ./so-manager.sh

# Search node
sudo ./so-search.sh

# Sensor (pass sensor number for auto-increment)
sudo ./so-sensor.sh 1    # so-sensor1 / 10.10.20.52
sudo ./so-sensor.sh 2    # so-sensor2 / 10.10.20.53
```

## Network Configuration

| Node | Hostname | IP | Role |
|---|---|---|---|
| Manager | so-manager | 10.10.20.10 | MANAGER (new deployment) |
| Search | sosearch | 10.10.20.51 | SEARCHNODE (existing deployment) |
| Sensor 1 | so-sensor1 | 10.10.20.52 | SENSOR (existing deployment) |
| Sensor 2 | so-sensor2 | 10.10.20.53 | SENSOR (existing deployment) |
| Sensor N | so-sensorN | 10.10.20.(51+N) | SENSOR (existing deployment) |

**Common settings across all nodes:**

- Gateway: 10.10.20.254
- DNS: 10.10.20.253
- DNS Search Domain: asat.tht (search/sensor), example.local (manager)
- Airgap: Yes
- NTP: 10.10.20.253

## Sensor Details

- Management NIC: ens192
- Sensor (monitor) NIC: ens224
- Admin user: Tester
- Zeek processors: 3
- Suricata processors: 3
- Hostname and IP auto-increment based on the sensor number argument

## Search Node Details

- Management NIC: ens192
- Install type: BASIC
- Metadata tool: Zeek
- Docker IP: Default
- Web interface access: IP

## Debugging

All override functions log to `/tmp/whiptail-debug.log` on the target VM. Check this file if the installer prompts unexpectedly — it means a whiptail function was called that doesn't have an override.

## Editing Values

Hardcoded values are in the `# ---- fixed values ----` section near the bottom of each `so-whiptail.*` file. Change values there before running the launcher script.
