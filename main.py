#!/usr/bin/env python3

import os
import subprocess
from decouple import config
from pathlib import Path

# env vars
region          = config('REGION', default='centralus')
subscription_id = config('SUBSCRIPTION_ID')
client_id       = config('CLIENT_ID')
client_secret   = config('CLIENT_SECRET')
tenant_id       = config('TENANT_ID')


def run_cmd(args):
    """Run command, transfer stdout/stderr back into this process's stdout/stderr"""
    print("Running command: %s" % " ".join(args))
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in iter(p.stdout.readline, b''):
        print(line.decode('utf-8').rstrip())
    p.stdout.close()
    return p.wait()


def main():
    # terraform init
    cmd = ["cd", "labs", "&&", "terraform", "init"]
    run_cmd(cmd)

    # terraform plan
    cmd = ["cd", "labs", "&&", "terraform", "plan", "-out=tfplan"]
    run_cmd(cmd)

    # terraform apply
    cmd = ["cd", "labs", "&&", "terraform", "apply", "-auto-approve"]
    run_cmd(cmd)


if __name__ == "__main__":
    main()
