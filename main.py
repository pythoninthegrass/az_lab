#!/usr/bin/env python3

import os
import re
import subprocess
import typer
from decouple import config
from pathlib import Path
from subprocess import Popen, PIPE, STDOUT
from typing import List, Optional
from typing_extensions import Annotated

# env vars
region          = config('REGION', default='centralus')
subscription_id = config('SUBSCRIPTION_ID')
client_id       = config('CLIENT_ID')
client_secret   = config('CLIENT_SECRET')
tenant_id       = config('TENANT_ID')

# dirs
tld = "terraform"
tf_dir = str(Path(f"{tld}/linux").resolve())
ch_dir = f"-chdir={tf_dir}"
ans_dir = str(Path("ansible").resolve())

# bin
tf = "terraform"

# typer init
app = typer.Typer(context_settings={
    "help_option_names": ["-h", "--help"]}
)


def run_cmd(args, shell=False):
    """Run command, transfer stdout/stderr back into this process's stdout/stderr"""
    print("Running command: %s" % " ".join(args))
    p = Popen(
        args,
        shell=shell,
        stdin=PIPE,
        stdout=PIPE,
        stderr=STDOUT)
    out = []
    with p.stdout:
        for line in iter(p.stdout.readline, b''):
            out += [line.decode('utf-8').rstrip()]
    p.wait()
    stdout = "\n".join([str(i) for i in out])
    print(stdout)
    return stdout


@app.command("hello")
def hello_world():
    """Debugging command"""
    cmd = ["echo", "hello world"]
    return run_cmd(cmd)


@app.command()
def tfi():
    """Run terraform init"""
    cmd = [tf, ch_dir, "init"]
    return run_cmd(cmd)


@app.command()
def tfp():
    """Run terraform plan"""
    cmd = [tf, ch_dir, "plan", "-out=tfplan"]
    return run_cmd(cmd)


@app.command()
def tfa():
    """Run terraform apply"""
    if not Path(f"{tf_dir}/tfplan").exists():
        print("tfplan does not exist, running plan first")
        tfp()
    cmd = [tf, ch_dir, "apply", "tfplan"]
    return run_cmd(cmd)


@app.command()
def tfs():
    """Run terraform show"""
    cmd = [tf, ch_dir, "show", "-json"]
    return run_cmd(cmd)


@app.command()
def get_ip():
    """Get Azure instance IP"""
    tf_state = Popen(
        [tf, ch_dir, "show", "-json"],
        stdin=PIPE,
        stdout=PIPE,
    )

    out = []
    with tf_state.stdout:
        for line in iter(tf_state.stdout.readline, b''):
            out += [line.decode('utf-8').rstrip()]

    az_ip = subprocess.run(
        ["jq", "-r", '.values.root_module.resources[] | select(.address == "azurerm_linux_virtual_machine.my_terraform_vm").values.public_ip_address'],
        input="\n".join([str(i) for i in out]),
        capture_output=True,
        text=True,
    ).stdout.strip()

    print(az_ip)
    return az_ip


@app.command()
def add_ip(*args):
    """Add Azure instance IP to Ansible inventory"""
    if args:
        az_ip = args[0]
    else:
        az_ip = get_ip()
    hosts = Path(f"{ans_dir}/hosts").read_text()
    if az_ip not in hosts:
        hosts = re.sub(r"\[azure\]\n", f"[azure]\n{az_ip}\n", hosts)
        Path(f"{ans_dir}/hosts").write_text(hosts)
        return print(Path(f"{ans_dir}/hosts").read_text())
    else:
        print(f"{az_ip} already in hosts file")


@app.command()
def rm_ip(*args):
    """Remove Azure instance IP from Ansible inventory"""
    hosts = Path(f"{ans_dir}/hosts").read_text()
    if not args:
        ip_address = get_ip()
    elif args:
        ip_address = args[0]
    else:
        print("No IP address specified")
        raise typer.Abort()

    if ip_address in hosts:
        hosts = re.sub(rf"{ip_address}\n", "", hosts)
        Path(f"{ans_dir}/hosts").write_text(hosts)
        return print(Path(f"{ans_dir}/hosts").read_text())
    else:
        print(f"{ip_address} not in hosts file")


# TODO: match multiple cases (case guard?)
@app.callback(invoke_without_command=True)
def main(command: Optional[str] = typer.Argument(None)):
    match command:
        case "tfi":
            tfi()
        case "tfp":
            tfp()
        case "tfa":
            tfa()
        case "tfs":
            tfs()
        case "get-ip":
            get_ip()
        case "add-ip":
            add_ip()
        case "rm-ip":
            rm_ip()
        case "hello":
            hello_world()
        case _:
            print("No command specified")


if __name__ == "__main__":
    app()
