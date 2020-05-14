#!/bin/bash

# Build image
echo "Building ElderberryPi Image..."

cd /vagrant
sudo packer build elderberrypi.json
