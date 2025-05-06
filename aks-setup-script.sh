#!/bin/bash

# Variables
date=$(date +%Y%m%d)
# Set the date variable to the current date in YYYYMMDD format
resourceGroup="cloud_project_aks"
location="westeurope"
containerRegistry="myacr20250503"
AKSCluster="myakscluster2025"
workspaceName="appworkspace20250503"
appinsightsName="ppinsight20250503"
# Function to check the last command's exit status
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting script."
        exit 1
    fi
}



# STEP 0 - Create resource group
echo "STEP 0 - Creating resource group $resourceGroup..."
az group create --name $resourceGroup --location $location --verbose
check_status "Resource group creation"
echo "Resource group created: $resourceGroup"

# STEP 1 - Create Azure Container Registry
echo "STEP 1 - Creating Azure Container Registry $containerRegistry..."
az acr create --resource-group $resourceGroup --name $containerRegistry --sku Basic
check_status "Azure Container Registry creation"
echo "Azure Container Registry created: $containerRegistry"

# STEP 2 - Create Kubernetes Cluster
echo "STEP 2 - Creating Kubernetes Cluster $AKSCluster and attaching it to ACR $containerRegistry..."
az aks create \
    --name $AKSCluster \
    --resource-group $resourceGroup \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr $containerRegistry \
    --location $location
check_status "Kubernetes Cluster creation"
echo "Kubernetes Cluster created: $AKSCluster"

# STEP 3 - Verify AKS permission to pull from ACR
echo "STEP 3 - Verifying AKS permission to pull from ACR $containerRegistry..."
az aks show \
  --resource-group $resourceGroup \
  --name $AKSCluster \
  --query "identityProfile.kubeletidentity.clientId" -o tsv
check_status "AKS permission verification"
echo "AKS permission verified."

# STEP 4 - Get credentials for AKS
echo "STEP 4 - Getting credentials for AKS $AKSCluster..."
az aks get-credentials --name $AKSCluster --resource-group $resourceGroup
check_status "Getting AKS credentials"
echo "Credentials for AKS $AKSCluster retrieved."


# STEP 5 - Verify connection to the cluster

echo "STEP 5 - Verifying connection to the cluster $AKSCluster..."

echo -e "\e[33muse these command to verify the connection\e[0m"

echo -e "\e[33mkubectl get nodes\e[0m"

echo -e "\e[33mkubectl get service azure-vote-front --watch\e[0m"

echo -e "\e[33mkubectl get service\e[0m"


# STEP 6 - Deploy the application
echo "STEP 6 - Deploying the application..."

echo  "\e[33muse these command to deploy the application\e[0m"

echo  "\e[33maz acr login --name $containerRegistry\e[0m"

echo  "\e[33maz acr show --name $containerRegistry --query loginServer --output table\e[0m"

echo  "\e[33mdocker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 $containerRegistry.azurecr.io/azure-vote-front:v1\e[0m"

echo  "\e[33mdocker push $containerRegistry.azurecr.io/azure-vote-front:v1\e[0m"

echo  "\e[33maz acr repository list --name $containerRegistry.azurecr.io --output table\e[0m"

echo  "\e[32mDeploy the images to the AKS cluster, make sure to do the necessary changes in the YAML file\e[0m"

echo  "\e[33maz acr show --name $containerRegistry --query loginServer --output table\e[0m"

echo  "\e[33mkubectl apply -f azure-vote-all-in-one-redis.yaml\e[0m"

echo  "\e[33mkubectl get service azure-vote-front --watch\e[0m"

echo  "\e[33mkubectl get service\e[0m"


echo  "\e[Troubleshoot\e[0m"
   

echo  "\e[kubectl get pods\e[0m"
    # It may require you to associate the AKS with the ACR
echo  "\e[az aks update -n $AKSCluster -g $resourceGroup --attach-acr $containerRegistry\e[0m"
    # Redeploy
echo  "\e[kubectl set image deployment azure-vote-front azure-vote-front=$containerRegistry.azurecr.io/azure-vote-front:v1\e[0m"

echo  "\e[Script completed successfully!\e[0m"

echo  "\e[33mYou can now access the application by running the following command:\e[0m"

echo  "\e[33maz aks browse --resource-group $resourceGroup --name $AKSCluster\e[0m"
