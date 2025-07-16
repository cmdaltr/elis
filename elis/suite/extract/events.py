#!/usr/bin/env python3 -tt
import re


def extract_auth_events(entry):
    try:
        fields = re.findall(
            r"^([A-Z][a-z]{2})\s(\d{2})\s(\d{2}:\d{2}:\d{2})\s([^ ]+)\s([^:]+)\[(\d+)\]:\s(.*)",
            entry.strip(),
        )[0]
    except IndexError:
        if len(fields) < 7:  # no PID
            fields = re.findall(
                r"^([A-Z][a-z]{2})\s(\d{2})\s(\d{2}:\d{2}:\d{2})\s([^ ]+)\s([^:]+)\]:\s(.*)",
                entry.strip(),
            )[0]
    except Exception as e:
        print(e)
    return fields


def extract_dmesg_events(entry):
    return fields


def extract_syslog_events(entry):
    return fields
