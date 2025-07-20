#!/usr/bin/env python3 -tt
from suite.payloads import *
import json
import re

jsondict = {}
jsonlist = []


def parse_logs(filename):
    log_to_ingest = filename + ".json"
    with open(log_to_ingest, "w") as logjson:
        logjson.write("[")
    with open(log_to_ingest, "a") as logjson:
        if "syslog" in filename or "auth.log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    match = re.match(
                        r"^([A-Z][a-z]{2})\s(\d{2})\s(\d{2}:\d{2}:\d{2})\s(\S+)\s?([^:]+)\[(\d+)\]:\s(.*)",
                        entry,
                    )
                    payload = None
                    if match:
                        fields = match.groups()
                        payload = build_syslog_pid_payload(fields)
                    else:
                        match = re.match(
                            r"^([A-Z][a-z]{2})\s(\d{2})\s(\d{2}:\d{2}:\d{2})\s(\S+)\s?([^:]+)\]?:\s(.*)",
                            entry,
                        )
                        if match:
                            fields = match.groups()
                            payload = build_syslog_nopid_payload(fields)
                    if payload:
                        jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "dmesg" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    match = re.match(
                        r"^\[\s*([\d\.]+)\]\s+([^:]+):\s(.*)", entry.strip()
                    )
                    if match:
                        fields = match.groups()
                        payload = build_dmesg_payload(fields)
                        jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "alternatives.log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    if "--install" in entry:
                        match = re.match(
                            r"^update-alternatives\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}): run with --install (\S+) (\S+) (\S+) (\d+)((?: --slave \S+ \S+ \S+)+)?",
                            entry.strip(),
                        )
                        if match:
                            fields = match.groups()
                            payload = build_altinstall_payload(fields)
                            jsonlist.append(json.dumps(payload))
                    elif "link group" in entry:
                        match = re.match(
                            r"^update-alternatives\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}): link group (\S+) updated to point to (\S+)",
                            entry.strip(),
                        )
                        if match:
                            fields = match.groups()
                            payload = build_altupdate_payload(fields)
                            jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "bootstrap.log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    if "URL:" in entry:
                        match = re.match(
                            r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) URL:(\S+) \[(\d+)/\d+\] -> \"([^\"]+)\" \[(\d+)\]",
                            entry.strip(),
                        )
                        if match:
                            fields = match.groups()
                            payload = build_bootapt_payload(fields)
                            jsonlist.append(json.dumps(payload))
                    elif "gpgv: " in entry:
                        match = re.match(
                            r"^gpgv: Signature made (.+)\ngpgv:\s+using (\S+) key (\S+)\ngpgv: Good signature from \"([^\"]+)\"",
                            entry.strip(),
                        )
                        if match:
                            fields = match.groups()
                            payload = build_bootgpg_payload(fields)
                            jsonlist.append(json.dumps(payload))
                    elif "dpkg: warning: " in entry:
                        match = re.match(
                            r"^dpkg: warning: parsing file '([^']+)' near line (\d+) package '([^']+)':\n missing '([^']+)' field",
                            entry.strip(),
                        )
                        if match:
                            fields = match.groups()
                            payload = build_bootwarn_payload(fields)
                            jsonlist.append(json.dumps(payload))
                    elif "dpkg: " in entry:
                        match = re.match(
                            r"^(?P<action>Selecting previously unselected package|Preparing to unpack|Unpacking|Setting up) (?P<package>[a-z0-9+.-]+)(?: \((?P<version>[^)]+)\))?",
                            entry.strip(),
                        )
                        if match:
                            fields = match.groups()
                            payload = build_bootdpkg_payload(fields)
                            jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "dpkg.log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    match = re.match(
                        r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (install|status|configure|upgrade) ([a-z0-9+.-]+):([a-z0-9]+) ([^\s]+)(?: ([^\s]+))?",
                        entry.strip(),
                    )
                    if match:
                        fields = match.groups()
                        payload = build_dpkg_payload(fields)
                        jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "kern.log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    match = re.match(
                        r"^(\w{3} \d{1,2} \d{2}:\d{2}:\d{2}) (\S+) kernel: \[\s*([\d.]+)\] (.+)",
                        entry.strip(),
                    )
                    if match:
                        fields = match.groups()
                        payload = build_kern_payload(fields)
                        jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "apt/history.log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    match = re.match(
                        r"(?ms)^Start-Date: (.+?)\n(.*?)(?:^End-Date: (.+?))$",
                        entry.strip(),
                    )
                    if match:
                        fields = match.groups()
                        payload = build_apthist_payload(fields, entry)
                        jsonlist.append(json.dumps(payload))
                jsondict.clear()
        elif "cups/access_log" in filename:
            with open(filename) as logfile:
                for entry in logfile:
                    match = re.match(
                        r"^(\S+) - (\S+) \[([^\]]+)\] \"(\S+) (\S+) ([^\"]+)\" (\d{3}) (\d+) (\S+) (\S+)",
                        entry.strip(),
                    )
                    if match:
                        fields = match.groups()
                        payload = build_cups_payload(fields)
                        jsonlist.append(json.dumps(payload))
                jsondict.clear()
        json_entries = list(set(jsonlist))
        for each in json_entries[0:-1]:
            logjson.write(f"{each},")
        logjson.write(f"{json_entries[-1]}]")
        jsonlist.clear()
