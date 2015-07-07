#!/bin/bash

source ./defaults.sh

# check if environment already exists
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel env list" | grep $FUEL_ENV_NAME > /dev/null 2>&1
if [[ "$?" == "0" ]]; then
    echo "INFO  : Deleting existing environment $FUEL_ENV_NAME"
    FUEL_ENV_ID=$(sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel env list" | grep $FUEL_ENV_NAME | awk '{print $1}')
    sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel env delete --env-id $FUEL_ENV_ID" > /dev/null 2>&1
fi

echo "INFO  : Creating fuel environment"
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel env create --name $FUEL_ENV_NAME --rel 1 --mode multinode --net neutron --nst vlan" > /dev/null 2>&1
if [[ "$?" != "0" ]]; then
    echo "ERROR : Failed creating fuel environment!"
    exit 1
fi
FUEL_ENV_ID=$(sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel env list" | grep $FUEL_ENV_NAME | awk '{print $1}')
echo "INFO  : Created fuel environment $FUEL_ENV_NAME with ID $FUEL_ENV_ID"

# get first node ID that is in discover mode assign controller role
NODE_ID=$(sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel node list" | grep discover | sort | head -n 1 | awk '{print $1}')
echo "INFO  : Assigning role controller to node with ID $NODE_ID"
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel node set --env $FUEL_ENV_ID --node $NODE_ID --role controller" > /dev/null 2>&1

# get next two node IDs that is in discuver mode and assign compute role
for NODE_ID in $(sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel node list" | grep discover | sort | tail -n 2 | awk '{print $1}'); do
    echo "INFO  : Assigning role compute to node with ID $NODE_ID"
    sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel node set --env $FUEL_ENV_ID --node $NODE_ID --role compute" > /dev/null 2>&1
done
STARTTIME=$(date +%s)
echo "INFO  : Starting OpenStack deployment on $(date)"
echo "        This may take a while..."
sshpass -p $FUEL_PASSWORD ssh $FUEL_USERNAME@$MASTER_VM_IP "fuel deploy-changes --env $FUEL_ENV_ID > /dev/null 2>&1"
if [[ "$?" != "0" ]]; then
    echo "ERROR : Deployment failed on $(date)"
    exit 1
fi
ENDTIME=$(date +%s)
echo "INFO  : Deployment completed successfully on $(date)"
echo "        It took $(($ENDTIME - $STARTTIME)) seconds to deploy"
echo "INFO  : Access OpenStack Horizon using http://10.20.0.3"
exit 0
