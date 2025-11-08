#!/usr/bin/env python3 -tt
from elasticsearch import Elasticsearch, helpers
from dotenv import load_dotenv, find_dotenv
import json
import os


load_dotenv(find_dotenv())
ELASTIC_HOST = os.getenv("ELASTIC_HOST")
ELASTIC_USERNAME = os.getenv("ELASTIC_USERNAME")
ELASTIC_PASSWORD = os.getenv("ELASTIC_PASSWORD")
SSL_VERIFY = False  # set to True if using a valid cert


def build_filebeat_yaml(LOG_PATH):
    if SSL_VERIFY == "False":
        sslmode = "None"
    with open("filebeat.yml", "w") as filebeatyml:
        filebeatyml.write(
            f"filebeat.inputs:\n- type: log  enabled: true\n  paths:\n    - {LOG_PATH}/*.json\n  json.keys_under_root: true\n  json.add_error_key: true\n  fields_under_root: true\n\noutput.elasticsearch:\n  hosts: [{ELASTIC_HOST}]\n  username: {ELASTIC_USERNAME}\n  password: {ELASTIC_PASSWORD}\n  ssl.verification_mode: {sslmode}"
        )


def convert_timestamps(data):
    # yyyy/MM/dd HH:mm:ss.SSS
    converted_timestamp_formats = re.sub(
        r"(@timestamp\": \"\d{4})/(\d{2})/(\d{2}) (\d{2}:\d{2}:\d{2}\.\d{3}[^\d])",
        r"\1-\2-\3 \4 000",
        data,
    )
    # yyyy-MM-dd HH:mm:ssZ/yyyy-MM-dd HH:mm:ss
    converted_timestamp_formats = re.sub(
        r"(@timestamp\": \"\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})Z?",
        r"\1 \2\.000000",
        converted_timestamp_formats,
    )
    # MM/dd/yy HH:mm:ss
    converted_timestamp_formats = re.sub(
        r"(@timestamp\": \"\d{2})/(\d{2})/(\d{2}) (\d{2}:\d{2}:\d{2})",
        r"\1-\2-\3 \4\.000000",
        converted_timestamp_formats,
    )
    # evtx files and $I30
    return (
        converted_timestamp_formats.replace(" 000", "000")
        .replace("000000.", ".")
        .replace("\\.000000", ".000000")
        .replace("\\..", ".")
    )


def ingest_logs(LOG_PATH):
    es = Elasticsearch(
        hosts=[ELASTIC_HOST],
        basic_auth=(ELASTIC_USERNAME, ELASTIC_PASSWORD),
        verify_certs=SSL_VERIFY,
    )

    hostname = "unknown"
    for root, _, files in os.walk(LOG_PATH):
        for f in files:
            if f.endswith(".json"):
                json_path = os.path.join(root, f)
                print(f"Indexing {json_path}")

                with open(json_path) as f_json:
                    try:
                        content = json.load(f_json)

                        # Normalize to list
                        if isinstance(content, dict):
                            docs = [content]
                        elif isinstance(content, list):
                            docs = content
                        else:
                            print(f"Unsupported format in {json_path}")
                            continue

                        actions = []
                        for doc in docs:
                            hostname = (
                                doc.get("host", {}).get("name", "unknown").lower()
                            )
                            index_name = f"logs-{hostname}"
                            actions.append(
                                {
                                    "_index": index_name,
                                    "_source": doc,
                                }
                            )

                        if actions:
                            helpers.bulk(es, actions)
                            print(f"Indexed {len(actions)} documents into {index_name}")

                    except json.JSONDecodeError as e:
                        print(f"Failed to parse {json_path}: {e}")
