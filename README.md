# elis (Elastic Log Ingestion Suite)

The Elastic Log Ingestion Suite facilitates the requirement of ingesting data into an elastic instance which is on an air-gapped/isolated network and where elastic agents cannot be deployed.
<br><br>

## Installation

Create `elis/elis/.env` and enter the following information for _your_ elastic instance:
```
ELASTIC_HOST = "https://your-elastic-server:9200"
ELASTIC_USERNAME = "elastic"
ELASTIC_PASSWORD = "changeme"
```

_**For macOS:**_ `brew install libmagic`<br><br>
`python3 -m pip install -r requirements.txt`
<br><br>

## Usage
`python3 elis.py`
<br><br>
