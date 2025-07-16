# pip install filemagic

#!/usr/bin/env python3 -tt
from suite.print import *
from suite.extract.archives import *
from suite.extract.events import *
import magic
import os


EXT_TYPES = {
    "txt": "text/plain",
    "7z": "application/x-7z-compressed",
    "zip": "application/zip",
    "tar": "application/x-tar",
    "tar.gz": "application/gzip",
    "tar.bz2": "application/x-bzip2",
}


def initial_extraction():
    for root, _, files in os.walk(os.path.join(os.getcwd(), "logs")):
        for f in files:
            fpath = os.path.join(root, f)
            if os.path.getsize(fpath) > 1000:
                filetype = check_filetype(fpath)
                if filetype != None:
                    if filetype != "text/plain":
                        extract_logs(fpath, filetype)


def check_filetype(fpath):
    with magic.Magic(flags=magic.MAGIC_MIME_TYPE) as mime:
        filetype = mime.id_filename(fpath)
        for _, types in EXT_TYPES.items():
            if types == filetype:
                return filetype
        print(
            f"\n [x] {fpath.split("/")[-1]} is not a valid file type and will be skipped."
        )


def build_payload(filename, fields):
    if "auth.log" in filename:
        payload = {
            "month": fields[0],
            "day": fields[1],
            "time": fields[2],
            "host": fields[3],
        }
        if len(fields) < 7:
            payload["process"] = "-"
            payload["pid"] = "-"
            payload["message"] = fields[4]
        else:
            payload["process"] = fields[4]
            payload["pid"] = fields[5]
            payload["message"] = fields[6]
    return payload


def parse_logs(fpath):
    with open(fpath) as log:
        for entry in log:
            print(entry.strip())
            if "auth.log" in fpath.split("/")[-1]:
                fields = extract_auth_events(entry)
            elif "dmesg" in fpath.split("/")[-1]:
                fields = extract_dmesg_events(entry)
            elif "syslog" in fpath.split("/")[-1]:
                fields = extract_syslog_events(entry)
            build_payload(fpath.split("/")[-1], fields)
    return


def main():
    initial_extraction()
    # perform another extraction if there are nested archives

    for root, _, files in os.walk(os.getcwd()):
        for f in files:
            fpath = os.path.join(root, f)
            if os.path.getsize(fpath) > 1000:
                filetype = check_filetype(fpath)
                if filetype == "text/plain":
                    parse_logs(fpath)


if __name__ == "__main__":
    main()
