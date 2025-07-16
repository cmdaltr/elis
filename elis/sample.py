import os
import json
from elasticsearch import Elasticsearch, helpers
import glob

# CONFIG
LOG_INPUT_DIR = "/opt/logs_to_ingest/"
ELASTIC_HOST = "https://your-elastic-server:9200"
ELASTIC_USERNAME = "elastic"
ELASTIC_PASSWORD = "changeme"
SSL_VERIFY = False  # set to True if using a valid cert

# Connect to Elasticsearch
es = Elasticsearch(
    ELASTIC_HOST,
    basic_auth=(ELASTIC_USERNAME, ELASTIC_PASSWORD),
    verify_certs=SSL_VERIFY,
)


def extract_hostname(log_entry: str) -> str:
    """Extract the hostname from a log entry. Adjust this logic for your format."""
    if "host" in log_entry:
        try:
            parsed = json.loads(log_entry)
            return parsed.get("host", {}).get("name", "unknown-host")
        except json.JSONDecodeError:
            pass
    elif "ComputerName=" in log_entry:
        return log_entry.split("ComputerName=")[-1].split()[0]
    return "unknown-host"


def process_log_file(filepath):
    """Parse a single log file and index to Elasticsearch."""
    with open(filepath, "r") as file:
        actions = []
        for line in file:
            hostname = extract_hostname(line)
            index_name = f"logs-{hostname.lower()}"
            try:
                log_doc = json.loads(line)
            except json.JSONDecodeError:
                log_doc = {"message": line.strip(), "host": {"name": hostname}}

            actions.append({"_index": index_name, "_source": log_doc})

        if actions:
            helpers.bulk(es, actions)
            print(f"Indexed {len(actions)} logs from {os.path.basename(filepath)}")


def main():
    log_files = glob.glob(os.path.join(LOG_INPUT_DIR, "*"))
    for log_file in log_files:
        process_log_file(log_file)


if __name__ == "__main__":
    main()
