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
# Create resource group. 
# This command will not work for the Cloud Lab users. 
# Cloud Lab users can comment this command and 
# use the existing Resource group name, such as, resourceGroup="cloud-demo-153430" 
echo "STEP 0 - Creating resource group $resourceGroup..."

az group create \
--name $resourceGroup \
--location $location \
--verbose

echo "Resource group created: $resourceGroup"

# Create Storage account
echo "STEP 1 - Creating storage account $storageAccount"

az storage account create \
--name $storageAccount \
--resource-group $resourceGroup \
--location $location \
--sku Standard_LRS

echo "Storage account created: $storageAccount"

# Create Network Security Group
echo "STEP 2 - Creating network security group $nsgName"

az network nsg create \
--resource-group $resourceGroup \
--name $nsgName \
--verbose

echo "Network security group created: $nsgName"

# Create VM Scale Set
echo "STEP 3 - Creating VM scale set $vmssName"

az vmss create \
  --resource-group $resourceGroup \
  --name $vmssName \
  --image $osType \
  --vm-sku $vmSize \
  --nsg $nsgName \
  --subnet $subnetName \
  --vnet-name $vnetName \
  --backend-pool-name $bePoolName \
  --storage-sku $storageType \
  --load-balancer $lbName \
  --custom-data cloud-init.txt \
  --upgrade-policy-mode automatic \
  --admin-username $adminName \
  --generate-ssh-keys \
  --verbose 

echo "VM scale set created: $vmssName"

# Associate NSG with VMSS subnet
echo "STEP 4 - Associating NSG: $nsgName with subnet: $subnetName"

az network vnet subnet update \
--resource-group $resourceGroup \
--name $subnetName \
--vnet-name $vnetName \
--network-security-group $nsgName \
--verbose

echo "NSG: $nsgName associated with subnet: $subnetName"

# Create Health Probe
echo "STEP 5 - Creating health probe $probeName"

az network lb probe create \
  --resource-group $resourceGroup \
  --lb-name $lbName \
  --name $probeName \
  --protocol tcp \
  --port 80 \
  --interval 5 \
  --threshold 2 \
  --verbose

echo "Health probe created: $probeName"

# Create Network Load Balancer Rule
echo "STEP 6 - Creating network load balancer rule $lbRule"

az network lb rule create \
  --resource-group $resourceGroup \
  --name $lbRule \
  --lb-name $lbName \
  --probe-name $probeName \
  --backend-pool-name $bePoolName \
  --backend-port 80 \
  --frontend-ip-name loadBalancerFrontEnd \
  --frontend-port 80 \
  --protocol tcp \
  --enable-floating-ip true \
  --verbose
#az network lb rule create --resource-group cloud_project --name udacity-vmss-lb-network-rule --lb-name udacity-vmss-lb --probe-name tcpProbe --backend-pool-name udacity-vmss-bepool --backend-port 80 --frontend-ip-name loadBalancerFrontEnd --frontend-port 80 --protocol tcp --enable-floating-ip --verbose
#az network lb rule show --resource-group cloud_project --lb-name udacity-vmss-lb --name udacity-vmss-lb-network-rule --query "enableFloatingIP"
#az network lb rule list --resource-group cloud_project --lb-name udacity-vmss-lb --output table

az vmss list-instance-connection-info --resource-group cloud_project --name udacity-vmss 

az network lb rule update --resource-group cloud_project --lb-name udacity-vmss-lb --name udacity-vmss-lb-network-rule  --enable-floating-ip true

echo "Network load balancer rule created: $lbRule"

# Add port 80 to inbound rule NSG
echo "STEP 7 - Adding port 80 to NSG $nsgName"

az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Port_80 \
--destination-port-ranges 80 \
--direction Inbound \
--priority 100 \
--verbose

az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Port_80 \
--destination-port-ranges 80 \
--direction Outbound \
--priority 100 \
--verbose

echo "Port 80 added to NSG: $nsgName"

# Add port 22 to inbound rule NSG
echo "STEP 8 - Adding port 22 to NSG $nsgName"

az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Port_22 \
--destination-port-ranges 22 \
--direction Inbound \
--priority 110 \
--verbose

az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Port_22 \
--destination-port-ranges 22 \
--direction Outbound \
--priority 110 \
--verbose

echo "Port 22 added to NSG: $nsgName"


echo "STEP 9 - Creating Bastion Host"

az network public-ip create \
  --resource-group $resourceGroup \
  --name ${bastionName}-public-ip \
  --sku Standard \
  --location $location \
  --allocation-method Static \
  --verbose
#az network public-ip create --resource-group cloud_project --name vmss-bastion-public-ip --sku Standard --location WestEurope --allocation-method Static --verbose
# Create VNet

az network vnet subnet create \
  --resource-group $resourceGroup \
  --vnet-name $vnetName \
  --name $BastionSubnet \
  --address-prefixes 10.0.1.0/26 \
  --verbose

#az network vnet subnet create --resource-group cloud_project --vnet-name udacity-vmss-vnet --name AzureBastionSubnet --address-prefixes 10.0.1.0/26 --verbose
# Create Bastion Host
# az network bastion create \
#   --name $bastionName \
#   --resource-group $resourceGroup \
#   --vnet-name $vnetName \
#   --location $location \
#   --sku Standard
#az network bastion create --name vmss-bastion --resource-group cloud_project --vnet-name udacity-vmss-vnet --location WestEurope --sku Standard

# Create Bastion Host with public IP
az network bastion create \
  --name $bastionName \
  --resource-group $resourceGroup \
  --vnet-name $vnetName \
  --location $location \
  --public-ip-address ${bastionName}-public-ip \
  --enable-tunneling true \
  --sku Standard \
  --verbose
# az network bastion create --name vmss-bastion --resource-group cloud_project --vnet-name udacity-vmss-vnet --location WestEurope --public-ip-address vmss-bastion-public-ip --sku Standard --verbose

az network nsg rule list \
  --resource-group $resourceGroup \
  --nsg-name $nsgName \
  --output table
#az network nsg rule list --resource-group cloud_project --nsg-name udacity-vmss-nsg --output table


az network bastion tunnel \
  --name "vmss-bastion" \
  --resource-group "cloud_project" \
  --target-resource-id "/subscriptions/f0c894e3-b3ff-403f-8417-bf591417d5eb/resourceGroups/cloud_project/providers/Microsoft.Compute/virtualMachines/udacity-vmss_7daa217e" \
  --resource-port 22 \
  --port 22 \
  --debug

# az network bastion tunnel \
#     --name "vmss-bastion" \
#     --resource-group "cloud_project"  \
#     --target-resource-id "/subscriptions/f0c894e3-b3ff-403f-8417-bf591417d5eb/resourceGroups/cloud_project/providers/Microsoft.Compute/virtualMachines/udacity-vmss_7daa217e" \
#     --resource-port 8000 \
#     --port 8000

# az network bastion tunnel --name "vmss-bastion" --resource-group "cloud_project" --target-resource-id "/subscriptions/f0c894e3-b3ff-403f-8417-bf591417d5eb/resourceGroups/cloud_project/providers/Microsoft.Compute/virtualMachines/udacity-vmss_7daa217e" --resource-port 80 --port 3000