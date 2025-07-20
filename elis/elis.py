#!/usr/bin/env python3 -tt
from dotenv import load_dotenv, find_dotenv
from suite.archives import *
from suite.elastic import *
from suite.parse import *
from suite.print import *
import magic
import os
import platform


load_dotenv(find_dotenv())
LOG_PATH = os.path.join(os.getcwd(), "logs")
EXT_TYPES = {
    "txt": "text/plain",
    "7z": "application/x-7z-compressed",
    "zip": "application/zip",
    "tar": "application/x-tar",
    "tar.gz": "application/gzip",
    "tar.bz2": "application/x-bzip2",
}


def archive_extraction():
    for root, _, files in os.walk(os.path.join(os.getcwd(), "logs")):
        for f in files:
            fpath = os.path.join(root, f)
            if os.path.getsize(fpath) > 100:
                filetype = check_filetype(fpath)
                if filetype != None:
                    if filetype != "text/plain":
                        extract_logs(fpath, filetype)


def check_filetype(fpath):

    def check_valid_file(filetype):
        for _, types in EXT_TYPES.items():
            if types == filetype:
                return filetype
        print(
            f"\n [x] {fpath.split('/')[-1]} is not a valid file type and will be skipped."
        )

    if platform.system() == "Darwin":  # python-magic (macOS)
        mime = magic.Magic(mime=True)
        filetype = check_valid_file(mime.from_file(fpath))
    else:  # filemagic (Linux)
        with magic.Magic(flags=magic.MAGIC_MIME_TYPE) as mime:
            filetype = check_valid_file(mime.id_filename(fpath))
    return filetype


def main():
    # extract all archive files
    NESTED_ARCHIVES = int(os.getenv("NESTED_ARCHIVES"))
    while 0 < NESTED_ARCHIVES:
        archive_extraction()
        NESTED_ARCHIVES -= 1

    # parse and convert log files to json
    for root, _, files in os.walk(LOG_PATH):
        for f in files:
            fpath = os.path.join(root, f)
            if os.path.getsize(fpath) > 100 and not fpath.endswith(".json"):
                filetype = check_filetype(fpath)
                if filetype == "text/plain":
                    parse_logs(fpath)

    # ingest into elastic
    ingest_logs(LOG_PATH)


if __name__ == "__main__":
    main()
