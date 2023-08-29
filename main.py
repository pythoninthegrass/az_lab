#!/usr/bin/env python3

import os
import re
import subprocess
import typer
from decouple import config
from pathlib import Path
from sh import jq
# from sh import terraform
from typing import List, Optional
from typing_extensions import Annotated

# env vars
region          = config('REGION', default='centralus')
subscription_id = config('SUBSCRIPTION_ID')
client_id       = config('CLIENT_ID')
client_secret   = config('CLIENT_SECRET')
tenant_id       = config('TENANT_ID')

tf = "terraform"
tf_dir = str(Path("terraform").resolve())
ch_dir = f"-chdir={tf_dir}"

ans_dir = str(Path("ansible").resolve())

app = typer.Typer(context_settings={
    "help_option_names": ["-h", "--help"]}
)


def run_cmd(args, verbose=True):
    """Run command, transfer stdout/stderr back into this process's stdout/stderr"""
    print("Running command: %s" % " ".join(args))
    if verbose:
        p = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT)
        out = []
        with p.stdout:
            for line in iter(p.stdout.readline, b''):
                out += [line.decode('utf-8').rstrip()]
        p.wait()
        return "\n".join([str(i) for i in out])
    else:
        p = subprocess.Popen(
            args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.STDOUT)
        p.wait()
        return p.returncode


@app.command("hello")
def hello_world():
    """Debugging command"""
    cmd = ["echo", "hello world"]
    return print(f"Command exited with code: {run_cmd(cmd, verbose=False)}")


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
    cmd = [tf, ch_dir, "apply", "tfplan", "-auto-approve"]
    return run_cmd(cmd)


@app.command()
def tfs():
    """Run terraform show"""
    cmd = [tf, ch_dir, "show", "-json"]
    return run_cmd(cmd)


@app.command()
def get_ip():
    """Get Azure instance IP"""
    # tf_state = terraform.show("-json", _cwd=tf_dir)
    tf_state = tfs()
    az_ip = jq(
        "-r",
        '.values.root_module.resources[] | select(.address == "azurerm_linux_virtual_machine.my_terraform_vm").values.public_ip_address',
        _in=tf_state,
    )
    print(az_ip)
    return az_ip.strip()


# TODO: debug args + match statement in main
@app.command()
def add_ip(*args: List[str]):
    """Add Azure instance IP to Ansible inventory"""
    if args:
        az_ip = args[0]
    else:
        az_ip = get_ip()
    hosts = Path(f"{ans_dir}/hosts").read_text()
    if az_ip not in hosts:
        hosts = hosts.replace("[azure]", f"[azure]\n{az_ip}")
        Path(f"{ans_dir}/hosts").write_text(hosts)
        return print(Path(f"{ans_dir}/hosts").read_text())
    else:
        print(f"{az_ip} already in hosts file")


@app.command()
def rm_ip(ip_address: str):
    """Remove Azure instance IP from Ansible inventory"""
    hosts = Path(f"{ans_dir}/hosts").read_text()
    if ip_address in hosts:
        # delete line with list comprehension
        hosts = "\n".join([i for i in hosts.split("\n") if i != ip_address])
        Path(f"{ans_dir}/hosts").write_text(hosts)
        return print(Path(f"{ans_dir}/hosts").read_text())
    else:
        print(f"{ip_address} not in hosts file")


@app.callback(invoke_without_command=True)
def main(command: Annotated[Optional[str], "command to run"] = typer.Argument(None)):
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
            ip = typer.prompt("IP address to remove")
            rm_ip(ip)
        case "hello":
            hello_world()
        case _:
            print("No command specified")


if __name__ == "__main__":
    app()
