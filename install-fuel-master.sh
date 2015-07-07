#!/bin/bash

source ./defaults.sh
source ./functions.sh

# create the VM for fuel-master
create_vm $MASTER_VM

# link ISO to BASEDIR
if [[ ! -f $FUEL_ISO ]]; then
    echo "ERROR : Unable to find $FUEL_ISO."
    echo "        Please download it from Mirantis website and place it under $BASEDIR"
    exit 1
fi

echo "INFO  : Inserting ISO and starting the OS installation of $MASTER_VM."
echo "        This may take a while..."
virsh change-media $MASTER_VM hdc --insert $FUEL_ISO > /dev/null 2>&1
virsh start $MASTER_VM > /dev/null 2>&1
sleep 5
virsh send-key $MASTER_VM KEY_ENTER > /dev/null 2>&1
sleep 30
export MASTER_INSTALL=1
for i in {1..720}; do
    virsh change-media $MASTER_VM hdc --eject > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        echo "INFO  : $MASTER_VM OS installation is completed! Ejected the installation media!"
        export MASTER_INSTALL=0
        break;
    fi
    sleep 1
done
virsh change-media $MASTER_VM hdc --eject > /dev/null 2>&1

if [[ "$MASTER_INSTALL" != "0" ]]; then
    echo "ERROR : $MASTER_VM OS installation failed!"
    exit 1
fi

echo "INFO  : Getting MAC address of the  eth0 of $MASTER_VM"
export NODE_MAC=$(virsh domiflist $MASTER_VM | grep fuel-net-0 | awk '{print $5}')
echo "INFO  : Acquired MAC address of the eth0 of $MASTER_VM"
echo "        $NODE_MAC"
echo "INFO  : Waiting for $MASTER_VM to accept SSH"
export NODE_IP=1
for i in {1..300}; do
    arp -e | grep $NODE_MAC > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        export NODE_IP=$(arp -e | grep $NODE_MAC | awk '{print $1}')
        echo "INFO  : Acquired IP of the $MASTER_VM"
        echo "        $NODE_IP"
        break;
    fi
    sleep 10
done

# check if we can SSH to fuel-master
export SSH_OK=1
for i in {1..150}; do
    sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "uname -an" > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        echo "INFO  : fuel-master accepts SSH"
        SSH_OK=0
        break
    fi
    sleep 10
done

if [[ "$NODE_IP" == "1" ]] || [[ "$SSH_OK" == "1" ]]; then
    echo "ERROR : $MASTER_VM OS installation failed!"
    exit 1
fi
sleep 30
echo "INFO  : $MASTER_VM OS installation is successful!"

export INSTALL_COMPLETE=1
echo "INFO  : Proceeding with Fuel installation and waiting for it to finish."
echo "        This may take a while..."

for i in {1..300}; do
    sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP  'grep "Fuel.*complete" /var/log/puppet/bootstrap_admin_node.log' > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        echo "INFO  : Fuel master installation is complete!"
        export INSTALL_COMPLETE=0
        break
    fi
    sleep 10
done

if [[ "$INSTALL_COMPLETE" != "0" ]]; then
    echo "ERROR : $MASTER_VM OS installation failed!"
    exit 1
fi

echo "INFO  : Bringing $MASTER_VM eth2 up and enabling internet connectivity"
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP 'ifup eth2' > /dev/null 2>&1
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP 'route add -net 192.168.122.0 netmask 255.255.255.0 eth2' > /dev/null 2>&1
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP 'route add default gw 192.168.122.1' > /dev/null 2>&1
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP \
    'echo nameserver 8.8.4.4 > /tmp/resolv.conf; \
     echo nameserver 8.8.4.4 >> /tmp/resolv.conf; \
     cat /etc/resolv.conf >> /tmp/resolv.conf; \
     mv -f /tmp/resolv.conf /etc/resolv.conf' > /dev/null 2>&1
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP 'ping -c 2 www.google.se' > /dev/null 2>&1
if [[ "$?" == "0" ]]; then
    echo "INFO  : Fuel master has internet connectivity"
else
    echo "WARN  : Fuel master does not have internet connectivity"
fi
echo "INFO  : Access Fuel dashboard using http://10.20.0.2:8000"
