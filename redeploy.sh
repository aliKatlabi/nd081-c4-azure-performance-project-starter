#!/bin/bash

# Variables


resourceGroup="cloud_project_aks"
location="westeurope"
containerRegistry="myacr20250503"
AKSCluster="myakscluster2025"

# Function to check the last command's exit status
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting script."
        exit 1
    fi
}




docker-compose up -d --build --force-recreate

# Create a resource group
az aks show \
  --resource-group $resourceGroup \
  --name $AKSCluster \
  --query "identityProfile.kubeletidentity.clientId" -o tsv

# az aks show --resource-group cloud_project_aks --name myakscluster2025 --query "identityProfile.kubeletidentity.clientId" -o tsv
check_status "AKS permission verification"
echo "AKS permission verified."

az acr login --name--name $containerRegistry
docker push $containerRegistry.azurecr.io/azure-vote-front:v1

kubectl apply -f azure-vote-all-in-one-redis.yaml

echo "get service ..."
kubectl get service
echo "get pods ..."
kubectl get pods


# Check if the deployment exists
if kubectl get deployment azure-vote-front > /dev/null 2>&1; then
    echo "Deployment exists. Updating..."
else
    echo "Deployment does not exist. Creating..."
    kubectl create deployment azure-vote-front --image=$containerRegistry.azurecr.io/azure-vote-front:v1
fi
# Update the image in the deployment
echo "Updating the image in the deployment..."
# Update the image in the deployment
kubectl set image deployment azure-vote-front azure-vote-front=$containerRegistry.azurecr.io/azure-vote-front:v1