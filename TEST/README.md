# ELIS Test Environment

This directory contains sample enterprise logs and a Dockerized Elasticsearch/Kibana environment for testing log ingestion.

---

## Prerequisites

- Docker Desktop installed and running
- Python 3.9+ (for ELIS)

---

## 1. Start Elasticsearch & Kibana

### Quick Start

```bash
cd elis/TEST
./setup.sh
```

This will:
1. Start Elasticsearch 8.12 with security enabled
2. Configure the `kibana_system` user
3. Start Kibana
4. Display connection details

### Manual Start (if preferred)

```bash
cd elis/TEST
docker compose up -d
```

Wait ~60 seconds for Elasticsearch to initialize, then set the Kibana password:

```bash
curl -k -X POST -u "elastic:changeme" \
  "https://localhost:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d '{"password": "changeme"}'
```

### Verify Elasticsearch is Running

```bash
curl -k -u "elastic:changeme" "https://localhost:9200/_cluster/health?pretty"
```

Expected output:
```json
{
  "cluster_name" : "elis-test-cluster",
  "status" : "green",
  ...
}
```

### Access Points

| Service       | URL                        | Credentials           |
|---------------|----------------------------|-----------------------|
| Elasticsearch | https://localhost:9200     | elastic / changeme    |
| Kibana        | http://localhost:5601      | elastic / changeme    |

---

## 2. Configure ELIS

### Option A: Use the TEST/.env file

The `.env` file in this directory is pre-configured:

```bash
cd elis/TEST
cat .env
```

```ini
ELASTIC_HOST=https://localhost:9200
ELASTIC_USERNAME=elastic
ELASTIC_PASSWORD=changeme
NESTED_ARCHIVES=2
```

### Option B: Update the main elis/.env file

```bash
cd elis
cat > .env << 'EOF'
ELASTIC_HOST=https://localhost:9200
ELASTIC_USERNAME=elastic
ELASTIC_PASSWORD=changeme
NESTED_ARCHIVES=2
EOF
```

---

## 3. Prepare Sample Logs for Ingestion

ELIS expects logs organized by hostname in the `logs/` directory:

```bash
cd elis

# Create hostname directories and copy sample logs
mkdir -p logs/WORKSTATION01
mkdir -p logs/ubuntu-srv-01
mkdir -p logs/fw-01
mkdir -p logs/web-srv-01
mkdir -p logs/dc01

# Copy samples to appropriate host directories
cp TEST/samples/windows_events/* logs/WORKSTATION01/
cp TEST/samples/ubuntu_syslog/* logs/ubuntu-srv-01/
cp TEST/samples/firewall_iptables/* logs/fw-01/
cp TEST/samples/cisco_asa/* logs/fw-01/
cp TEST/samples/apache_nginx/* logs/web-srv-01/
cp TEST/samples/ids_suricata/* logs/web-srv-01/
cp TEST/samples/active_directory/* logs/dc01/
cp TEST/samples/dns_logs/* logs/dc01/
cp TEST/samples/dhcp/* logs/dc01/
cp TEST/samples/mail_postfix/* logs/dc01/
cp TEST/samples/proxy_squid/* logs/web-srv-01/
```

Your logs directory should now look like:

```
elis/logs/
├── WORKSTATION01/
│   └── security.xml
├── ubuntu-srv-01/
│   ├── syslog
│   └── auth.log
├── fw-01/
│   ├── iptables.log
│   └── asa_logs.log
├── web-srv-01/
│   ├── access.log
│   ├── error.log
│   ├── eve.json
│   └── access.log (squid)
└── dc01/
    ├── security_audit.log
    ├── query.log
    ├── dhcpd.log
    └── mail.log
```

---

## 4. Run ELIS

### Activate the virtual environment

```bash
cd elis
source .venv/bin/activate
```

### Run the ingestion

```bash
python3 elis.py
```

ELIS will:
1. Extract any archives in the logs directory
2. Parse log files and convert to JSON
3. Ingest documents into Elasticsearch

**Note:** The Elasticsearch ingestion step in `elis.py` may be commented out. If so, uncomment line ~69 in `elis.py`:

```python
# Uncomment this line to enable ingestion:
# elastic.bulk_ingest(json_docs, hostname)
```

---

## 5. Verify Ingestion in Kibana

1. Open Kibana: http://localhost:5601
2. Log in with `elastic` / `changeme`
3. Go to **Management** → **Stack Management** → **Index Management**
4. You should see indices like:
   - `logs-workstation01`
   - `logs-ubuntu-srv-01`
   - `logs-fw-01`
   - `logs-web-srv-01`
   - `logs-dc01`

### Create a Data View

1. Go to **Management** → **Stack Management** → **Data Views**
2. Click **Create data view**
3. Name: `logs-*`
4. Index pattern: `logs-*`
5. Timestamp field: `@timestamp`
6. Click **Save data view to Kibana**

### Explore the Logs

1. Go to **Analytics** → **Discover**
2. Select the `logs-*` data view
3. Adjust the time range to cover the log timestamps (Feb 7, 2026)

---

## 6. Threat Hunting Queries

The sample logs contain various attack indicators. Try these KQL queries in Discover:

### Brute Force Attempts
```
message: "Failed password" OR message: "authentication failure"
```

### Suspicious Outbound Connections
```
dest_ip: "185.220.101.35" OR dest_ip: "185.234.72.15"
```

### Privilege Escalation
```
message: "Domain Admins" OR message: "sudo" OR EventID: 4732
```

### Malware Indicators
```
message: "mimikatz" OR message: "powershell" AND message: "-enc"
```

### Data Exfiltration
```
message: "transfer.sh" OR message: "pastebin" OR message: "mega.nz"
```

### Web Attacks
```
message: "sqlmap" OR message: "SQL Injection" OR message: "XSS"
```

---

## 7. Stop the Environment

```bash
cd elis/TEST
./stop.sh
```

### Remove All Data (Clean Reset)

```bash
cd elis/TEST
docker compose down -v
```

This removes the Elasticsearch data volume, giving you a fresh start.

---

## Troubleshooting

### Elasticsearch won't start

Check logs:
```bash
docker compose logs elasticsearch
```

Common issues:
- **vm.max_map_count too low**: Run `sudo sysctl -w vm.max_map_count=262144`
- **Not enough memory**: Ensure Docker has at least 4GB RAM allocated

### Certificate errors with curl

Use the `-k` flag to skip certificate verification:
```bash
curl -k -u "elastic:changeme" "https://localhost:9200"
```

### ELIS SSL verification errors

In `suite/elastic.py`, ensure `verify_certs=False`:
```python
es = Elasticsearch(
    hosts=[ELASTIC_HOST],
    basic_auth=(ELASTIC_USERNAME, ELASTIC_PASSWORD),
    verify_certs=False
)
```

### Kibana shows "Kibana server is not ready yet"

Wait 1-2 minutes. If it persists:
```bash
docker compose logs kibana
```

Ensure the `kibana_system` password was set correctly (run `setup.sh` again).

---

## Sample Log Summary

| Directory | Log Type | Threat Scenarios |
|-----------|----------|------------------|
| `cisco_asa/` | Cisco ASA firewall | VPN brute force, port scans, C2 blocking |
| `ubuntu_syslog/` | Linux syslog/auth | SSH brute force, reverse shells, backdoor users |
| `windows_events/` | Windows Security XML | Failed logins, mimikatz, privilege escalation |
| `firewall_iptables/` | iptables | Port scans, SYN floods, blocked C2 |
| `apache_nginx/` | Web server | SQLi, XSS, web shells, enumeration |
| `dns_logs/` | BIND DNS | DNS tunneling, DGA domains, C2 lookups |
| `proxy_squid/` | Squid proxy | Blocked malware, data exfiltration |
| `ids_suricata/` | Suricata IDS | CobaltStrike, ETERNALBLUE, various alerts |
| `dhcp/` | ISC DHCP | Rogue hosts, IP conflicts |
| `mail_postfix/` | Postfix MTA | SMTP brute force, spam, malware attachments |
| `active_directory/` | AD Security | Kerberoasting, DCSync, account manipulation |
