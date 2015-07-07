# fuel-libvirt
Simple and dirty scripts to deploy nested 3-node OpenStack environment using Mirantis Fuel 6.0

# Description
This set of scripts automates the deployment of an experimental OpenStack environment using Mirantis Fuel 6.0.
The deployed OpenStack environment consists of 3-nodes; 1 controller and 2 compute nodes. These scripts are created and tested on Ubuntu 14.04.2.

# Prerequisites

- Download Mirantis Fuel ISO from [Mirantis website] [1] and save it as $HOME/Downloads/MirantisOpenStack-6.0.iso.
- Install packages - libvirt, sshpass and might be others.

# How to Use

First clone this repo and just execute fuel-libvirt.sh.

# What Happens Next

When you execute the script fuel-libvirt.sh, it follows below steps to deploy OpenStack.

- cleanup: Remove any existing networks, pools, volumes, and VMs that might be leftovers of previous deployment.
- create networks: Create 4 networks; fuel-net-0, fuel-net-1, fuel-net-2, and fuel-net-nat, mark them for autostart, and start them.
- create pool: Create a pool named fuel to place volumes, mark it for autostart, and start it.
- create and install fuel master: Create a VM for fuel master, install the OS, install Fuel, enable internet connectivity.
- create fuel slaves: Create 3 VMs for fuel slaves and make them PXE-boot.
- deploy OpenStack: Start the deployment using fuel once the slave nodes are discovered by Fuel master.

[1]: https://software.mirantis.com/openstack-download-form/
