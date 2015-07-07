#!/bin/bash
set -o nounset

# find out the directory where scripts and configs are located
export TOP_DIR=$(readlink -f $(dirname $0))

source ./defaults.sh
source ./functions.sh

[[ -d $BASEDIR ]] && rm -rf $BASEDIR

cleanup
create_networks
create_pool
./install-fuel-master.sh
./create-fuel-slaves.sh
./deploy-openstack.sh
