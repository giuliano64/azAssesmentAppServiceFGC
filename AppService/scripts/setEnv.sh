﻿cd
rm -rf azAssesmentAppServiceFGC
git clone https://github.com/giuliano64/azAssesmentAppServiceFGC.git
cd azAssesmentAppServiceFGC
# Create Resource Group
resourceGroupName='appsrv-rg'
resourceGroupLocation='southcentralus'
resourceGroup=$(az group create --name ${resourceGroupName} --location ${resourceGroupLocation} --verbose)

### Deploy App Service
appsrv='appsrv'

# Create Service Principal
spName=sp-appService
sp=$(az ad sp create-for-rbac --name ${spName})

cd AppService


# Deploy Log Analytics Workspace
templateFile="./Templates/logAnalytics.json"

timestamp=$(date -u +%FT%TZ | tr -dc '[:alnum:]\n\r')
name="$(echo $resourceGroup | jq .name -r)-${timestamp}"
deployment=$(az group deployment create --resource-group $(echo $resourceGroup | jq .name -r) --name ${name} --template-file ${templateFile} --verbose)


#create keyvault
keyVaultName=${appsrv}-kv 
#create keyvault
az keyvault create \
  --name $(echo $keyVaultName) \
  --resource-group  $(echo $resourceGroup | jq .name -r) \
  --location "southcentralus" \
  --enabled-for-template-deployment true

az keyvault set-policy -n  $(echo $keyVaultName) --spn $(echo $sp | jq .appId -r) --secret-permissions get list set --key-permissions create decrypt delete encrypt get list unwrapKey wrapKey
#az keyvault secret set --vault-name $(echo $keyVaultName) --name "appSrvSpPWD" --value  $(echo $sp | jq .password -r) 

#deploy Vnet with 2 subnets
vnetTemplate="./Templates/appServiceVnet.json"
vnetName='appVnet'
vnetDeployment=$(az group deployment create --resource-group $(echo $resourceGroup | jq .name -r) --name  $(echo $vnetName) --template-file ${vnetTemplate} --verbose)


# Deploy App Service with WebApp
logAnalyticsId=$(echo $deployment | jq .properties.outputs.workspaceResourceId.value -r)
az group deployment create \
    -g $(echo $resourceGroup | jq .name -r)  \
    --template-file "Templates/azuredeploy.json" \
 

 az group deployment create \
    -g $(echo $resourceGroup | jq .name -r)  \
    --template-file "Templates/dataLake.json" \


cd