#!/bin/bash

# Variables
resourceGroup="cloud_project"
location="WestEurope"
osType="Ubuntu2204"
vmssName="udacity-vmss"
adminName="udacityadmin"
storageAccount="udacitydiag123$RANDOM"
bePoolName="$vmssName-bepool"
lbName="$vmssName-lb"
lbRule="$lbName-network-rule"
nsgName="$vmssName-nsg"
vnetName="$vmssName-vnet"
subnetName="$vnetName-subnet"
probeName="tcpProbe"
vmSize="Standard_B1s"
storageType="Standard_LRS"
bastionName="vmss-bastion"
BastionSubnet="AzureBastionSubnet"
vm1name="udacity-vmss_8d1bfe93"
# Prompt user to choose tunneling option
echo "Choose the tunneling option:"
echo "1. Tunnel resource port 22 to local port 2222 (for SSH and file transfer)"
echo "2. Tunnel resource port 80 to local port 3000 (for HTTP access)"
read -p "Enter your choice (1 or 2): " choice


# Get the resource ID of the specific VM instance
targetResourceId=$(az vm show \
-g cloud_project \
--name udacity-vmss_8d1bfe93 \
--query "id" \
-o tsv)


echo "Target Resource ID: $targetResourceId"

# Perform tunneling based on user choice
if [ "$choice" -eq 1 ]; then
  echo "Tunneling resource port 22 to local port 2222..."
  echo "You can use the following commands to copy files or connect via SSH:"
  echo "scp -r ./azure-vote/ udacityadmin@localhost:/home/udacityadmin/azure-vote/"
  echo "ssh udacityadmin@localhost"
  
  az network bastion tunnel \
    --name $bastionName \
    --resource-group $resourceGroup \
    --target-resource-id $targetResourceId \
    --resource-port 22 \
    --port 2222

  #az network bastion tunnel --name bastion --resource-group cloud_project --target-resource-id '/subscriptions/f0c894e3-b3ff-403f-8417-bf591417d5eb/resourceGroups/cloud_project/providers/Microsoft.Compute/virtualMachineScaleSets/udacity-vmss' --resource-port 22 --port 22

az network bastion ssh --name "bastion" --resource-group "cloud_project" --target-ip-address "4.180.90.143" --auth-type "password" --username "udacityadmin" 

  echo "Tunnel created. Use the following command to copy files or connect via SSH:"
  


elif [ "$choice" -eq 2 ]; then
  echo "Tunneling resource port 80 to local port 3000..."
  az network bastion tunnel \
    --name $bastionName \
    --resource-group $resourceGroup \
    --target-resource-id $targetResourceId \
    --resource-port 80 \
    --port 3000
  echo "Tunnel created. Access the application in your browser at http://localhost:3000"
else
  echo "Invalid choice. Exiting."
  exit 1
fi

echo "Operation completed successfully!"