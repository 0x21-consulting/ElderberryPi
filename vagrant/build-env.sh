#!/bin/bash

#
# Setup ARM emulation and packer
#

# Try and resolve hostname in advance for go-getter go plugin
ping -c 1 proxy.golang.org

# Update the system
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get clean

# Add golang repo
sudo apt-get install -y software-properties-common
sudo add-apt-repository --yes ppa:longsleep/golang-backports
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    kpartx \
    qemu-user-static \
    git \
    wget \
    curl \
    vim \
    unzip \
    golang-go \
    gcc \
    python3-distutils
sudo apt-get clean

# Set GO paths for vagrant user
echo 'export GOROOT=/usr/lib/go-1.14
export GOPATH=$HOME/work
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' | tee -a /home/vagrant/.profile
source /home/vagrant/.profile

# Download and install packer
[[ -e /tmp/packer ]] && rm /tmp/packer
wget https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip \
    -q -O /tmp/packer_1.5.5_linux_amd64.zip
cd /tmp
unzip -u packer_1.5.5_linux_amd64.zip
sudo mv packer /usr/local/bin
rm packer_1.5.5_linux_amd64.zip

# Build the packer-builder-arm-image plugin for Packer
mkdir -p $GOPATH/src/github.com/solo-io/
cd $GOPATH/src/github.com/solo-io/
rm -rf packer-builder-arm-image # clean from previous builds
git clone https://github.com/solo-io/packer-builder-arm-image
cd packer-builder-arm-image
go build

# Copy plugin
if [[ ! -f packer-builder-arm-image ]]; then
  echo "Error Plugin failed to build."
  exit
else
  cp packer-builder-arm-image /vagrant/
fi

