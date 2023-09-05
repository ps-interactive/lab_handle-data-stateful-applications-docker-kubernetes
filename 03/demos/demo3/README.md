# Secret Store CSI Driver

- External secure storage
- Kubernetes SecretProviderClass CRD
- Mounting external secrets into Pods

## Pre-requisites

This demo uses the CSI Secrets driver with Kubernetes running on Azure, so Pods can read Secrets stored in Azure KeyVault. You can follow along by creating an Azure Kubernetes Service cluster from the [AKS](./aks.md) docs.

You'll need to be in the `demo3` directory.

## External secure storage

I have my AKS cluster already deployed and set up with the CSI storage provider:

```
kubectl get nodes

kubectl get crd
```

And I have a KeyVault store with my Products API configuration file stored in a secret:

```
az keyvault list -o table

az keyvault secret list --vault-name ps-kv01 -o table

az keyvault secret show -n products-api-config --vault-name ps-kv01 -o table
```

> This is encrypted at rest and in transit, and requires specific Azure permissions to access

## Kubernetes SecretProviderClass CRD

Access to the KeyVault secret is modelled using a SecretProviderClass:

- [keyVault.yaml](.\prod-with-config\secretProviderClasses\keyVault.yaml) - creates a Secret provider which can load the Products API config file from KeyVault

The Kubernetes cluster needs to be authorized to the underlying secret store. In AKS we have a Managed Identity automatically created, but we need to specify the identity ID in the YAML:

```
az aks show -g ps-storage -n ps-aks01 --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
```

Deploy the KeyVault Secret provider class:

```
kubectl apply -f .\prod-with-config\secretProviderClasses\

kubectl get secretproviderclass
```


## Mounting external secrets into Pods

With the infrastructure in place the application model is simple:

- [products-api.yaml](.\prod-with-config\products-api.yaml) - replaces the Secret volume with the secret store CSI provider

CSI volumes can only be mounted into the container filesystem. We can't use KeyVault secrets for the Stock API configuration, because that component only loads config from environment variables.

We'll create a Kubernetes Secret for the Stock API:

```
kubectl create secret generic stock-api-config-db --from-env-file ./secrets/stock-api/db.env

kubectl label secret/stock-api-config-db app=wiredbrain component=stock-api
```

And deploy the app - the rest of the spec is the same as we've used locally on Docker Desktop:

```
kubectl apply -f prod-with-config/configMaps  -f prod-with-config/

kubectl get po

kubectl get svc
```

> Browse to the external IP - this is the same set of Docker images, now configured with multiple config sources.


Now the only Kubernetes Secret is for the Stock API:

```
kubectl get secret -l app=wiredbrain
```

The Products API loads configuration directly from KeyVault without storing it in Kubernetes.

But the config is still in plain text inside the container filesystem:

```
kubectl exec deploy/products-api -- cat /app/config/db/application.properties
```

> The only alternative to this is to use a secret store API directly in code and not load config from the environment.