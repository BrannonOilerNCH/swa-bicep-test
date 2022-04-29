### Deploy to IS-managed resource group
az deployment group create \
	--name BicepTest \
	--resource-group itripoc-rg \
	--template-file src/main.bicep \
	--parameters @parameters.json

### Deploy to personal account at a subscription level
# az deployment sub create \
# 	--name BasicSubscription \
# 	--location eastus2 \
# 	--template-file src/main.bicep \
# 	--parameters @parameters.json
