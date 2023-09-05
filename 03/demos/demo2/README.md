# Secrets in Kubernetes

- Modelling Secrets
- Managing data in Secrets
- Securing access with RBAC

## Pre-requisites

You just need Kubernetes for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Desktop on Linux](https://docs.docker.com/desktop/linux/).

You'll need to be in the `demo2` directory.

_Check your setup:_

```
kubectl get nodes

pwd
```

_And deploy the app from Demo 1 if you don't have it running:_

```
k apply -f ../demo1/prod-with-config/configMaps -f ../demo1/prod-with-config/configMaps/update -f ../demo1/prod-with-config
```

## Modelling Secrets

ConfigMaps isolate configuration settings from the app, but they're intended for non-sensitive data.

You can read the contents of a ConfigMap in plain text:

```
kubectl get configmap -l app=wiredbrain

kubectl describe cm web-config-api
```

These are all pretty safe, and reading them easily helps with troubleshooting so it's fine to have them in a ConfigMap.

But the API configuration does have sensitive data:

```
kubectl describe cm products-api-config-db
```

> All the database connection details are visble

We'll replace the app model to use Secrets. Start by removing the existing app components:

```
kubectl get cm,deploy -l app=wiredbrain

kubectl delete cm,deploy -l app=wiredbrain

kubectl get po
```

Secrets are objects like ConfigMaps. You can model them in YAML or create them directly from the source data:

- [db.env](./secrets/stock-api/db.env) - has the database configuration to load into the Stock API as environment variables

- [application.properties](./secrets/products-api/application.properties) - has the database config to load into the Products API filesystem

Create a Secret for the Stock API:

```
kubectl create secret generic stock-api-config-db --from-env-file ./secrets/stock-api/db.env
```

And a Secret for the Products API:

```
kubectl create secret generic products-api-config-db --from-file ./secrets/products-api/application.properties
```

The Deployments have been updated to use Secrets instead of ConfigMaps:

- [stock-api.yaml](./prod-with-config/stock-api.yaml) - loads the Secret into container environment variables

- [products-api.yaml](./prod-with-config/products-api.yaml) - replaces the ConfigMap volume with the Secret

We can update the existing objects:

```
kubectl apply -f prod-with-config/configMaps/ -f prod-with-config/

kubectl get po --watch
```

> The app is still working at http://localhost:8088


## Secrets and Base64

The app works in the same way, but now the sensitive config items are stored in Secrets, which aren't printed in plain text:

```
kubectl get secret

kubectl describe secret products-api-config-db
```

**But** Secrets are not encrypted in the Kubernetes API and you can access the data. It's shown as base-64 encoded, which is easy to decode:

```
kubectl get secret products-api-config-db -o yaml

kubectl get secret products-api-config-db -o go-template='{{.data}}'

kubectl get secret products-api-config-db -o go-template='{{index .data /"application.properties/"}}'

kubectl get secret products-api-config-db -o go-template='{{index .data /"application.properties/" | base64decode}}'

```

> Oh.


## Using RBAC to restrict access

The benefit of Secrets is that they are a different object type, so you can permission them separately using RBAC. These roles give different access to SRE and test users:

- [sre.yaml](./rbac/sre.yaml) - SRE users have read and write permissions for ConfigMaps and Secrets

- [tester.yaml](./rbac/tester.yaml) - testers only have access to Pods

> I've deployed these settings and created users for each group following the [RBAC](./rbac.md) doc.

Check the permissions:

```
kubectl get rolebindings -o wide

kubectl auth can-i get secrets --as-group sre --as siobhan

kubectl auth can-i get secrets --as-group tester --as rishi
```

Switching to Siobhan's credentials, I can see the Secret content:

```
kubectl config use-context siobhan

kubectl get secret products-api-config-db -o go-template='{{index .data /"application.properties/" | base64decode}}'
```

But as Rishi I can't see the Secrets at all:

```
kubectl config use-context rishi

kubectl get secret products-api-config-db -o go-template='{{index .data /"application.properties/" | base64decode}}'

kubectl get secrets --all-namespaces
```

But the test user does have `exec` access to help debug issues, and that means they can access the container filesystem:

```
kubectl get po --show-labels

kubectl describe po -l component=products-api

kubectl exec <products-api-pod> -- cat /app/config/db/application.properties
```