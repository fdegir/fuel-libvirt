#!/bin/bash

source ./defaults.sh
source ./functions.sh

echo "INFO  : Waiting 60 seconds in order for $MASTER_VM to stabilize"
sleep 60
echo "INFO  : Creating fuel slaves"
for SLAVE_VM in $SLAVE_VMS; do
    create_vm $SLAVE_VM
    virsh start $SLAVE_VM > /dev/null 2>&1
done
echo "INFO  : Waiting for slave nodes to be ready"
echo "        This may take a while..."

no_of_slaves=$(echo $SLAVE_VMS | wc -w)
wait_loop=0
while [[ $wait_loop -lt 40 ]]; do
    for SLAVE_VM in $SLAVE_VMS; do
        NODE_MAC=$(virsh domiflist $SLAVE_VM | grep fuel-net-0 | awk '{print $5}')
        NODE_STATUS=$(sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP 'fuel node list' | grep $NODE_MAC | awk '{print $3}')
        if [[ "$NODE_STATUS" == "discover" ]]; then
            no_of_slaves=$[$no_of_slaves-1]
            echo "        Slave node $SLAVE_VM is ready!"
            SLAVE_VMS=$(echo $SLAVE_VMS | sed "s/$SLAVE_VM//g")
        fi
    done
    if [[ $no_of_slaves -eq 0 ]]; then
        break
    fi
    wait_loop=$[$wait_loop+1]
    sleep 10
done

if [[ $no_of_slaves -eq 0 ]]; then
    echo "INFO  : All nodes are ready!"
else
    echo "ERROR : $no_of_slaves of the node(s) failed to get ready!"
    echo "        Exiting!"
    exit 1
fi
