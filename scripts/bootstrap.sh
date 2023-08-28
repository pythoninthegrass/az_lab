#!/usr/bin/env bash

# shellcheck disable=SC2086,SC2164,SC2317

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)

# remove files/dirs
clean_up() {
	printf "Removing %s\n" "$@"
	rm -rf "$@"
}

# call function on EXIT SIGINT SIGTERM
trap_card() {
	echo "Caught EXIT/SIGINT/SIGTERM."
	cd "${script_dir}"
	clean_up /opt/linuxtools.7z
	clean_up /opt/{impacket,CrackMapExec,helk,john-*,Responder,SilentTrinity}
}
trap trap_card EXIT SIGINT SIGTERM

# install python3.11
sudo apt update && sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update && sudo apt install -y \
	ansible ansible-lint curl dnsutils git python3.11 python3.11-venv p7zip-full tree

# set path for pip
[[ -n $(logname >/dev/null 2>&1) ]] && logged_in_user=$(logname) || logged_in_user=$(whoami)
logged_in_home=$(eval echo "~${logged_in_user}")
export PATH=${PATH//":${logged_in_home}/.local/bin"/}

# install pip
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# install tools
sudo chmod 777 /opt
curl -LJ https://github.com/pythoninthegrass/apt_lab_tf_linux/raw/master/linuxtools.7z \
	-o /opt/linuxtools.7z
7z x -y /opt/linuxtools.7z -o/opt
mkdir -p /opt/{CrackMapExec,SilentTrinity}
mv /opt/st /opt/SilentTrinity/
mv /opt/cme* /opt/CrackMapExec/
git clone https://github.com/lgandx/Responder.git /opt/Responder

# install impacket and setup venv
git clone https://github.com/SecureAuthCorp/impacket.git /opt/impacket
python3.11 -m venv /opt/impacket/env

# TODO: run on x86_64 vm w/4cpu, 5gb ram, 20gb disk
# clone and run helk container
git clone https://github.com/Cyb3rWard0g/HELK.git /opt/helk
sudo /opt/helk/docker/helk_install.sh -p hunting -i 10.10.98.20 -b 'helk-kibana-analysis-alert'

exit 0
