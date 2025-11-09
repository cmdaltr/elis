# elis (Elastic Log Ingestion Suite)

The Elastic Log Ingestion Suite facilitates the requirement of ingesting data into an Elasticsearch instance on an air-gapped/isolated network where Elastic agents cannot be deployed.

## Features

- **Offline deployment** - Package dependencies on macOS, deploy to Linux without internet
- **Archive extraction** - Automatically extracts nested archives (7z, zip, tar, tar.gz, tar.bz2)
- **Log parsing** - Parses various log formats and converts to JSON
- **Elasticsearch ingestion** - Ingests logs into air-gapped Elasticsearch instances
- **Cross-platform** - Build on macOS, deploy to Oracle Linux

## Quick Start

### 1. Configuration

Create `.env` in the root directory with your Elasticsearch credentials:
```bash
ELASTIC_HOST = "https://your-elastic-server:9200"
ELASTIC_USERNAME = "elastic"
ELASTIC_PASSWORD = "changeme"
NESTED_ARCHIVES = 2
```

### 2. Build Deployment Package (macOS)

```bash
# Package for Oracle Linux Python 3.9
./config.sh --package --python 3.9 --zip

# This creates packages.zip containing:
# - All dependencies (Python wheels for Linux & macOS)
# - Source code (elis.py, suite/)
# Note: Transfer config.sh separately
```

### 3. Deploy to Oracle Linux (Offline)

```bash
# Transfer BOTH files to your Oracle Linux machine
scp packages.zip config.sh user@linux:/path/to/destination/

# On Oracle Linux (no internet required):
./config.sh --install-linux

# This will:
# - Auto-extract packages.zip
# - Create a virtual environment (.venv)
# - Install all dependencies from local wheels
# - Run elis.py
```

### 4. Preparing Logs

Place log files (archived or unarchived) in `logs/`:
```bash
logs/
├── syslog.1.gz
├── application.log
└── archived-logs.7z
```

Set `NESTED_ARCHIVES` in `.env` to the number of archive layers:
- `0` = No archives, only plain log files
- `1` = One layer of archives (e.g., syslog.1.gz)
- `2+` = Multiple nested archives

> **Note:** Linux systems often auto-archive logs (e.g., syslog.1.gz), so setting this to 2+ is recommended.

## Usage

### macOS Development

```bash
# Install dependencies
brew install libmagic
python3 -m pip install -r requirements.txt

# Run
python3 elis.py
```

### Oracle Linux (After Deployment)

```bash
# From the directory where you extracted packages.zip
./config.sh --install-linux
```

## config.sh Options

```bash
# Build & Package
./config.sh --package --python 3.9 --zip   # Package for Python 3.9 (Oracle Linux)

# Installation
./config.sh --install-linux                # Install on Linux (creates .venv)
./config.sh --install-macos                # Install on macOS

# Maintenance
./config.sh --reset                        # Clean all build artifacts
./config.sh --help                         # Show all options
```

## Directory Structure

```
elis/
├── elis.py              # Main script
├── suite/               # Module directory
│   ├── archives.py      # Archive extraction
│   ├── elastic.py       # Elasticsearch client
│   ├── parse.py         # Log parsing
│   ├── payloads.py      # Payload generation
│   └── print.py         # Logging utilities
├── logs/                # Runtime logs directory
├── config.sh            # Build & deployment script
├── requirements.txt     # Python dependencies
└── .env                 # Configuration (create this)
```

## Requirements

- **macOS:** Python 3.13+, Docker Desktop, libmagic
- **Oracle Linux:** Python 3.9+ (no other dependencies required for deployment)

## Troubleshooting

**"pip: command not found" on Linux:**
- The script automatically bootstraps pip from included wheels

**"No module named 'dotenv'" error:**
- Ensure you're running from inside the `packages/` directory
- The virtual environment is created automatically

**Wrong Python version:**
- Specify target version: `./config.sh --package --python 3.9`
- Check Linux version: `python3 --version`
