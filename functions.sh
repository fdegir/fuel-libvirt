#!/bin/bash
set -o nounset

# cleanup everything
cleanup () {
    # remove all the VMs and volumes
    for VM in $(echo $MASTER_VM $SLAVE_VMS); do
        virsh dominfo $VM > /dev/null 2>&1
        if [[ "$?" == "0" ]]; then
            virsh destroy $VM > /dev/null 2>&1
            virsh undefine $VM > /dev/null 2>&1
        fi

        volume_name="$VM.img"
        virsh vol-info --pool $POOL_NAME $volume_name > /dev/null 2>&1
        if [[ "$?" == "0" ]]; then
            virsh vol-delete --pool $POOL_NAME $volume_name > /dev/null 2>&1
        fi
        echo "INFO  : Deleted the VM $VM and its volume"
    done

    # remove the pool
    virsh pool-info $POOL_NAME >& /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        virsh pool-destroy $POOL_NAME >& /dev/null 2>&1
        virsh pool-undefine $POOL_NAME >& /dev/null 2>&1
        [[ -d $POOL_TARGET ]] || rm -rf $POOL_TARGET
    fi

    virsh pool-info $POOL_NAME >& /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        echo "ERROR : Unable to delete pool $POOL_NAME"
        exit 1
    else
        echo "INFO  : Deleted the pool $POOL_NAME"
    fi

    # remove the networks first
    for FUEL_NETWORK in $FUEL_NETWORKS; do
        virsh net-info $FUEL_NETWORK > /dev/null 2>&1
        if [[ "$?" == "0" ]]; then
            virsh net-destroy $FUEL_NETWORK > /dev/null 2>&1
            virsh net-undefine $FUEL_NETWORK > /dev/null 2>&1
            echo "INFO  : Deleted the network $FUEL_NETWORK"
        fi
    done
}

# delete the networks if they exist, recreate them
# mark them for autostart and start the networks
create_networks() {
    echo "INFO  : Creating networks"
    for FUEL_NETWORK in $FUEL_NETWORKS; do
        virsh net-define --file $TOP_DIR/networks/$FUEL_NETWORK.xml > /dev/null 2>&1
        if [[ "$?" != "0" ]]; then
            echo "ERROR : Unable to create network $FUEL_NETWORK!"
            exit 1
        fi

        virsh net-autostart $FUEL_NETWORK > /dev/null 2>&1
        virsh net-start $FUEL_NETWORK > /dev/null 2>&1
        echo "INFO  : Created network $FUEL_NETWORK and started it"
    done

    echo "INFO  : List of fuel networks"
    echo "----------------------------------------------------------"
    echo "$(virsh net-list | grep 'fuel-')"
    echo "----------------------------------------------------------"
}

# delete the pool if exists, create the directory for it,
# define new pool, mark it for autostart and start the pool
create_pool() {
    # create the directory for the pool if it doesn't exist already
    [[ -d $POOL_TARGET ]] || mkdir -p $POOL_TARGET

    # create the pool
    virsh pool-info $POOL_NAME >& /dev/null 2>&1
    if [[ "$?" != "0" ]]; then
        virsh pool-define-as --name $POOL_NAME \
                             --type $POOL_TYPE \
                             --target $POOL_TARGET >& /dev/null 2>&1

        virsh pool-autostart $POOL_NAME >& /dev/null 2>&1
        virsh pool-start $POOL_NAME >& /dev/null 2>&1
    else
        echo "ERROR : Pool $POOL_NAME still exists.";
        exit 1
    fi

    # print info to console
    virsh pool-info $POOL_NAME >& /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        echo "INFO  : Created pool $POOL_NAME in $POOL_TARGET"
        echo "----------------------------------------------------------"
        echo "$(virsh pool-info $POOL_NAME)"
        echo "----------------------------------------------------------"
    else
        echo "ERROR : Unable to create pool $POOL_NAME"
        exit 1
    fi
}

# delete the volume if exists and create the volume for VM
create_volume() {
    vm="$1"

    if [[ -z "$vm" ]]; then
        echo "ERROR : VM name must be specified!"
        exit 1
    fi
    volume_name="$1.img"

    virsh vol-create-as --name $volume_name \
                        --format $VOLUME_FORMAT \
                        --capacity $VOLUME_CAPACITY \
                        --pool $POOL_NAME > /dev/null 2>&1
    if [[ "$?" != "0" ]]; then
        echo "ERROR : Unable to create volume for VM $vm"
        exit 1
    else
        echo "INFO  : Created the volume for VM $vm"
        echo "----------------------------------------------------------"
        echo "$(virsh vol-info --pool $POOL_NAME $volume_name)"
        echo "----------------------------------------------------------"
    fi

}

# destroy and undefine the VM and create it
create_vm() {
    vm_name=$1
    volume="$POOL_TARGET/$vm_name.img"

    echo "INFO  : Removing $vm_name VM if it exists and creating it"

    create_volume $vm_name

    cat $TOP_DIR/vms/$vm_name.xml \
        | sed "s|#VM_VOLUME#|$volume|g" > /tmp/vm_name_$$.xml
    virsh define /tmp/vm_name_$$.xml > /dev/null 2>&1
    virsh dominfo $vm_name > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        echo "INFO  : Created VM $vm_name successfully!"
        echo "----------------------------------------------------------"
        echo "$(virsh dominfo $vm_name)"
        echo "----------------------------------------------------------"
        rm /tmp/vm_name_$$.xml
    else
        echo "ERROR : Failed creating $vm_name! Exiting."
        exit 1
    fi
}
