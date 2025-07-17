#!/usr/bin/env python3 -tt
import re

def build_syslog_pid_payload(fields):
    payload = {
        "@timestamp": f"2025-{fields[0]}-{fields[1]} {fields[2]}", # require year
        "host": fields[3],
    }
    payload["process"] = fields[4]
    payload["pid"] = fields[5]
    payload["message"] = fields[6]
    return payload


def build_syslog_nopid_payload(fields):
    payload = {
        "@timestamp": f"2025-{fields[0]}-{fields[1]} {fields[2]}", # require year
        "host": fields[3],
    }
    payload["message"] = fields[4]
    return payload


def build_dmesg_payload(fields):
    payload = {
        "@timestamp": fields[0], # not provided
    }
    payload["uptime"] = fields[0]
    payload["source"] = fields[1]
    payload["message"] = fields[2]
    return payload


def build_altinstall_payload(fields):
    payload = {
        "@timestamp": fields[0],
    }
    payload["install_link"] = fields[1]
    payload["process"] = fields[2]
    payload["path"] = fields[3]
    payload["priority"] = fields[4]
    payload["slaves"] = fields[5]
    return payload


def build_altupdate_payload(fields):
    payload = {
        "@timestamp": fields[0],
    }
    payload["process"] = fields[1]
    payload["path"] = fields[2]
    return payload


def build_bootapt_payload(fields):
    payload = {
        "@timestamp": fields[0],
    }
    payload["url"] = fields[1]
    payload["bytes"] = fields[2]
    payload["path"] = fields[3]
    payload["status"] = fields[4]
    return payload


def build_bootgpg_payload(fields):
    payload = {
        "@timestamp": fields[0],
    }
    payload["key_type"] = fields[1]
    payload["key_id"] = fields[2]
    payload["signer"] = fields[3]
    return payload


def build_bootwarn_payload(fields):
    payload = {}
    payload["path"] = fields[0]
    payload["line_no"] = fields[1]
    payload["package"] = fields[2]
    payload["missing_field"] = fields[3]
    return payload


def build_bootdpkg_payload(fields):
    payload = {}
    payload["action"] = fields[0]
    payload["package"] = fields[1]
    payload["version"] = fields[2]
    return payload


def build_dpkg_payload(fields):
    payload = {
        "@timestamp": fields[0],
    }
    payload["action"] = fields[1]
    payload["package"] = fields[2]
    payload["arch"] = fields[3]
    payload["version"] = fields[4]
    payload["new_version"] = fields[5]
    return payload


def build_kern_payload(fields):
    payload = {
        "@timestamp": fields[0],
    }
    payload["hostname"] = fields[1]
    payload["uptime"] = fields[2]
    payload["message"] = fields[3]
    return payload


def build_apthist_payload(fields, entry):
    payload = {
        "@timestamp": fields[0],
        "endtime": fields[-1],
    }
    if "Requested-By" in fields[1]:
        contents = re.findall(r"(?:Requested-By: (\S+) \((\d+)\)\n)", entry.strip())
        payload["user"] = contents[0]
        payload["uid"] = contents[1]
    if "Commandline" in fields[1]:
        contents = re.findall(r"(?:Commandline: (.+?)\n)", entry.strip())
        payload["command"] = contents[0]
    if "Install" in fields[1] or "Remove" in fields[1] or "Purge" in fields[1] or "Upgrade" in fields[1]:
        contents = re.findall(r"((?:^(?:Install|Remove|Purge|Upgrade): .+))", entry.strip())
        payload["action"] = contents[0]


def build_cups_payload(fields):
    payload = {
        "@timestamp": fields[2],
    }
    payload["hostname"] = fields[0]
    payload["user"] = fields[1]
    payload["method"] = fields[3]
    payload["path"] = fields[3]
    payload["protocol"] = fields[3]
    payload["status"] = fields[3]
    payload["bytes"] = fields[3]
    payload["action"] = fields[3]
    payload["result"] = fields[3]
    return payload
