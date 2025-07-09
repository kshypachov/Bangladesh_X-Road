#!/bin/bash

set -e

# === 1 install Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git openjdk-21-jdk
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo adduser $USER docker
# === 2 Clone X-Road repo
git clone https://github.com/nordic-institute/X-Road.git
cd X-Road/
git checkout tags/7.6.2
./src/prepare_buildhost.sh
./src/build_packages.sh -r noble --skip-tests
