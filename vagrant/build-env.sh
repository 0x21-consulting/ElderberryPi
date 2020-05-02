#!/bin/bash

#
# Setup ARM emulation and packer
#

PACKER_VERSION="1.5.6"

# Update the system
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y autoremove
sudo apt-get clean

# Install required packages
sudo apt-get install -y \
  qemu-user-static \
  ca-certificates \
  dosfstools \
  gdisk \
  kpartx \
  libarchive-tools \
  git \
  golang-go \
  unzip
sudo apt-get clean

# Download and install packer
command -v packer >/dev/null 2>&1 || {
  wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -O /tmp/packer.zip && \
  sudo unzip /tmp/packer.zip -d /bin && \
  rm /tmp/packer.zip
}

# Download and build packer-builder-arm
if [ ! -f /vagrant/packer-builder-arm ]; then
  git clone https://github.com/mkaczanowski/packer-builder-arm
  cd packer-builder-arm
  go mod download
  go build
  cp packer-builder-arm /vagrant/
fi
