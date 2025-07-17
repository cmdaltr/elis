#!/usr/bin/env python3 -tt
from elasticsearch import Elasticsearch, helpers
from dotenv import load_dotenv
import os


load_dotenv(dotenv_path="../.env")
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
        ELASTIC_HOST,
        basic_auth=(ELASTIC_USERNAME, ELASTIC_PASSWORD),
        verify_certs=SSL_VERIFY,
    )

    for root, _, files in os.walk(LOG_PATH):
        for f in files:
            if f.endswith(".json"):
                json_to_ingest = os.path.join(root, f)
                """read file as json
                define index by reading the hostname field from log (have a default value)
                index_name = f"logs-{hostname.lower()}"
                json_doc = {"message": jsonblob, "host": {"name": hostname}}
                actions.append({"_index": index_name, "_source": json_doc})
                if actions:
                    helpers.bulk(es, actions)
                    print(
                        f"Indexed {len(actions)} logs from {os.path.basename(filepath)}"
                    )"""

                """with open(os.path.join(atftroot, atftfile)) as read_json:
                        json_content = read_json.read()
                    in_json = StringIO(json_content)
                    results = [json.dumps(record) for record in json.load(in_json)]
                    with open(
                        os.path.join(atftroot, atftfile)[0:-5] + ".ndjson", "w"
                    ) as write_json:
                        for result in results:
                            if result != "{}":
                                data = '{{"index": {{"_index": "{}"}}}}\n{{"hostname": "{}", "artefact": "{}", {}\n\n'.format(
                                    case.lower(),
                                    img.split("::")[0],
                                    atftfile,
                                    result[1:]
                                    .replace("SystemTime", "@timestamp")
                                    .replace("LastWriteTime", "@timestamp")
                                    .replace("LastWrite Time", "@timestamp")
                                    .replace('"LastWrite": "', '"@timestamp": "')
                                    .replace(
                                        '"@timestamp": "@timestamp ',
                                        '"@timestamp": "',
                                    ),
                                )
                                data = re.sub(r'(": )(None)([,:\}])', r'\1"\2"\3', data)
                                converted_timestamp = convert_timestamps(data)
                                write_json.write(converted_timestamp)

                                ingest_data_command = shlex.split(
                                    'curl -s -H "Content-Type: application/x-ndjson" -XPOST localhost:9200/{}/_doc/_bulk?pretty --data-binary @"{}"'.format(
                                        case.lower(), ndjsonfile
                                    )
                                )
                                ingested_data = subprocess.Popen(
                                    ingest_data_command,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE,
                                ).communicate()[0]
                                if "Unexpected character" in str(ingested_data) or 'failed" : 1' in str(
                                    ingested_data
                                ):
                                    print(
                                        "       Could not ingest\t'{}'\t- perhaps the json did not format correctly?".format(
                                            ndjsonfile.split("/")[-1]
                                        )
                                    )"""
