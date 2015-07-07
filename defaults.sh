#!/bin/bash

# script defaults

# set where the pool and volumes are located
export BASEDIR="$HOME/fuel-libvirt"

# set where the Mirantis-Fuel.iso is
export FUEL_ISO=$HOME/Downloads/MirantisOpenStack-6.0.iso

# set where the Mirantis-Fuel.iso is
export FUEL_ENV_NAME=fuel-libvirt
export FUEL_USERNAME=root
export FUEL_PASSWORD=r00tme

# networks
export FUEL_NETWORKS="fuel-net-0 fuel-net-1 fuel-net-2 fuel-net-nat"

# vms
export MASTER_VM="fuel-master"
export MASTER_VM_IP="10.20.0.2"
export SLAVE_VMS="fuel-slave-1 fuel-slave-2 fuel-slave-3"

# pool defaults
export POOL_NAME="fuel"
export POOL_TYPE="dir"
export POOL_TARGET="$BASEDIR/pool"

# volume defaults
export VOLUME_CAPACITY="30G"
export VOLUME_FORMAT="raw"
