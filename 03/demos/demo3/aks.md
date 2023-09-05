# AKS with KeyVault Secret Storage

You can easily create a Kubernetes cluster in Azure which is connected to a KeyVault store for sensitive configuration:

- [Use the Azure Key Vault Provider for Secrets Store CSI Driver in an AKS cluster](https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)

This is what you need to do:

_Set some variables:_

```
$rg='ps-storage'
$aks='ps-aks01'
$kv='ps-kv01'
```

_Create a Resource Group:_

```
az group create -n $rg -l eastus
```

_Create an AKS cluster with the KeyVault provider add-on:_

```
az aks create -g $rg -n $aks --node-count 2 --enable-addons azure-keyvault-secrets-provider --enable-managed-identity
```

_Now create a KeyVault:_

```
az keyvault create -g $rg -n $kv
```

_And store the Products API config file as a KeyVault secret:_

```
az keyvault secret set --name products-api-config --vault-name $kv  --file ./secrets/products-api/application.properties
```

_Now [provide access for the Managed Identity](https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access#use-a-user-assigned-managed-identity) so the AKS nodes can access the KeyVault_:

```
$id=$(az aks show -g $rg -n $aks --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

az keyvault set-policy -n $kv --secret-permissions get --spn $id
```

_Connect to your AKS cluster:_

```
az aks get-credentials  -g $rg -n $aks
```