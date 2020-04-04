#!/bin/bash

set -e

# Copy executable to plugins directory. Why this doesn't work in the
# build-env script is beyond me.
mkdir -p /home/vagrant/.packer.d/plugins
cp -v /vagrant/packer-builder-arm-image /home/vagrant/.packer.d/plugins/

# Build image
echo "Attempting to build image"
#PACKER_LOG_PATH=/vagrant/packer.log
#PACKER_LOG=$PACKER_LOG_PATH
PACKER_RESULTS=$(mktemp)
cd /vagrant
sudo packer build blueberrypi.json #| tee ${PACKER_RESULTS}
BUILD_NAME=$(grep -Po "(?<=Build ').*(?=' finished.)" ${PACKER_RESULTS})
IMAGE_PATH=$(grep -Po "(?<=--> ${BUILD_NAME}: ).*" ${PACKER_RESULTS})
rm -f ${PACKER_RESULTS}

# Move image
sudo mv ${IMAGE_PATH} ${IMAGE_PATH%/image}.img
sudo rmdir ${IMAGE_PATH%/image}

