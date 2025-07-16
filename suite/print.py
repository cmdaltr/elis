#!/usr/bin/env python3 -tt
import time


def print_success(fpath):
    print(f"Successfully extracted {fpath.split("/")[-1]}!")
    time.sleep(2)


def print_incorrect_passwd(fpath):
    print(f" [x] Incorrect password for {fpath.split("/")[-1]}, please try again...")


def print_fail(fpath):
    print(f" [x] Failed to extract {fpath}")


def print_corrupt(fpath):
    print(f" [x] Skipping {fpath}, it is likely corrupted...")
