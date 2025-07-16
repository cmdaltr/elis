#!/usr/bin/env python3 -tt
from datetime import datetime
from suite.print import *
import getpass
import os
import py7zr
import tarfile
import zipfile


def request_password(fpath):
    return input(f"Please enter password for {fpath}: ")
    return getpass.getpass(f"Please enter password for {fpath}: ")


def get_timestamp():
    return (
        str(datetime.now().replace(microsecond=0))
        .replace("-", "")
        .replace(":", "")
        .replace(" ", "")
    )


def extract_7z_password_archive(fpath, output_dir):
    def extract_7z(fpath, output_dir, passwrd):
        with py7zr.SevenZipFile(fpath, password=passwrd) as archive:
            archive.extractall(path=output_dir)
        print_success(fpath)

    passwrd = request_password(fpath)
    passwrd = passwrd.strip()
    try:
        extract_7z(fpath, output_dir, passwrd)
    except Exception as e:
        if "invalid block data" in str(e):
            print_incorrect_passwd(fpath)
            extract_7z_password_archive(fpath, output_dir)


def extract_zip_password_archive(fpath, output_dir):
    def extract_zip(fpath, output_dir, passwrd):
        with zipfile.ZipFile(fpath) as archive:
            archive.extractall(
                output_dir, pwd=passwrd.encode("utf-8")
            )  # Password must be in bytes
        print_success(fpath)

    passwrd = request_password(fpath)
    passwrd = passwrd.strip()
    try:
        extract_zip(fpath, output_dir, passwrd)
    except Exception as e:
        if "Bad password for file" in str(e):
            print_incorrect_passwd(fpath)
            extract_zip(fpath, output_dir)


def extract_tar(fpath, output_dir, mode):
    try:
        with tarfile.open(fpath, mode) as archive:
            archive.extractall(path=output_dir, filter="data")
        print_success(fpath)
    except:
        print_fail(fpath)


def extract_logs(fpath, filetype):
    timestamp = get_timestamp()
    output_dir = f"{timestamp}_{fpath.split("/")[-1].split(".")[0]}"
    os.makedirs(output_dir, exist_ok=True)

    if filetype == "application/x-7z-compressed":
        try:
            with py7zr.SevenZipFile(fpath) as archive:
                archive.extractall(path=output_dir)
        except Exception as e:
            if "Password is required" in str(e):
                extract_7z_password_archive(fpath, output_dir)
    elif filetype == "application/zip":
        try:
            with zipfile.ZipFile(fpath, "r") as archive:
                archive.extractall(output_dir)
        except Exception as e:
            if "password required" in str(e):
                extract_zip_password_archive(fpath, output_dir)
    elif filetype == "application/x-tar":
        extract_tar(fpath, output_dir, "r")
    elif filetype == "application/gzip":
        extract_tar(fpath, output_dir, "r:gz")
    elif filetype == "application/x-bzip2":
        extract_tar(fpath, output_dir, "r:bz2")
