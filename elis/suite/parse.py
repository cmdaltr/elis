#!/usr/bin/env python3 -tt
from elis.suite.payloads import *
import json
import re

jsondict = {}
jsonlist = []

def parse_logs(filename):
        log_to_ingest = filename + ".json"
        with open(log_to_ingest, "a") as logjson:
            if filename.endswith("syslog") or filename.endswith("auth.log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        try:
                            fields = re.findall(
                                r"^([A-Z][a-z]{2})\s(\d{2})\s(\d{2}:\d{2}:\d{2})\s([^ ]+)\s([^:]+)\[(\d+)\]:\s(.*)",
                                entry.strip(),
                            )[0]
                            payload = build_syslog_pid_payload(fields)
                        except IndexError:  # no PID
                            fields = re.findall(
                                r"^([A-Z][a-z]{2})\s(\d{2})\s(\d{2}:\d{2}:\d{2})\s([^ ]+)\s([^:]+)\]?:\s(.*)",
                                entry.strip(),
                            )[0]
                            payload = build_syslog_nopid_payload(fields)
                        except Exception as e:
                            print(e)
                            break
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("dmesg"):
                with open(filename) as logfile:
                    for entry in logfile:
                        fields = re.findall(r"^\[\s*[\d\.]+\]\s+([^:]+):\s(.*)", entry.strip())[0]
                        payload = build_dmesg_payload(fields)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("alternatives.log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        if "--install" in entry:
                            fields = re.findall(r"^update-alternatives\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}): run with --install (\S+) (\S+) (\S+) (\d+)((?: --slave \S+ \S+ \S+)+)?", entry.strip())
                            payload = build_altinstall_payload(fields)
                        elif "link group" in entry:
                            fields = re.findall(r"^update-alternatives\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}): link group (\S+) updated to point to (\S+)", entry.strip())
                            payload = build_altupdate_payload(fields)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("bootstrap.log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        if "URL:" in entry:
                            fields = re.findall(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) URL:(\S+) \[(\d+)/\d+\] -> \"([^\"]+)\" \[(\d+)\]", entry.strip())
                            payload = build_bootapt_payload(fields)
                        elif "gpgv: " in entry:
                            fields = re.findall(r"^gpgv: Signature made (.+)\ngpgv:\s+using (\S+) key (\S+)\ngpgv: Good signature from \"([^\"]+)\"", entry.strip())
                            payload = build_bootgpg_payload(fields)
                        elif "dpkg: warning: " in entry:
                            fields = re.findall(r"^dpkg: warning: parsing file '([^']+)' near line (\d+) package '([^']+)':\n missing '([^']+)' field", entry.strip())
                            payload = build_bootwarn_payload(fields)
                        elif "dpkg: " in entry:
                            fields = re.findall(r"^(?P<action>Selecting previously unselected package|Preparing to unpack|Unpacking|Setting up) (?P<package>[a-z0-9+.-]+)(?: \((?P<version>[^)]+)\))?", entry.strip())
                            payload = build_bootdpkg_payload(fields)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("dpkg.log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        fields = re.findall(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (install|status|configure|upgrade) ([a-z0-9+.-]+):([a-z0-9]+) ([^\s]+)(?: ([^\s]+))?", entry.strip())[0]
                        payload = build_dpkg_payload(fields)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("kern.log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        fields = re.findall(r"^(\w{3} \d{1,2} \d{2}:\d{2}:\d{2}) (\S+) kernel: \[\s*([\d.]+)\] (.+)", entry.strip())
                        payload = build_kern_payload(fields)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("apt/history.log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        fields = re.findall(r"(?ms)^Start-Date: (.+?)\n(.*?)(?:^End-Date: (.+?))$", entry.strip())
                        payload = build_apthist_payload(fields, entry)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            elif filename.endswith("cups/access_log"):
                with open(filename) as logfile:
                    for entry in logfile:
                        fields = re.findall(r"^(\S+) - (\S+) \[([^\]]+)\] \"(\S+) (\S+) ([^\"]+)\" (\d{3}) (\d+) (\S+) (\S+)", entry.strip())
                        payload = build_cups_payload(fields)
                        jsonlist.append(json.dumps(payload))
                    jsondict.clear()
            for each in jsonlist:
                print(each)
                import time
                time.sleep(20)
                #logjson.write(log_json)
            jsonlist.clear()

