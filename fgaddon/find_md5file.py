#!/usr/bin/python

import os, sys, re, fnmatch
import hashlib, glob


def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


filepath = sys.argv[1]
searchpath = sys.argv[2]

digest = md5(filepath)
print("Checking for " + digest)

wavfiles = glob.glob(searchpath + "/**/*.wav", recursive=True)

for f in wavfiles:
    if (md5(f) == digest):
        print(f)