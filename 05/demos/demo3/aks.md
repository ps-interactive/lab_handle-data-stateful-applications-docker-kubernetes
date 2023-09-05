# AKS with Multiple Nodes

Kubernetes clusters in Azure are configured by default with CSI drivers for Azure storage.

_Set some variables:_

```
$rg='ps-storage'
$aks='ps-aks-m5'
```

_Create a Resource Group:_

```
az group create -n $rg -l eastus
```

_Create an AKS cluster with the KeyVault provider add-on:_

```
az aks create -g $rg -n $aks --node-count 2 --generate-ssh-keys
```

_Connect to your AKS cluster:_

```
az aks get-credentials  -g $rg -n $aks
```