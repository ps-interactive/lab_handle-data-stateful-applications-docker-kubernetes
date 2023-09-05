
# Persistent Volumes and Claims

- Losing data during updates
- Requesting storage with Persistent Volume Claims
- Understanding Storage Classes and provisioners

## Pre-requisites

You just need Kubernetes for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Desktop on Linux](https://docs.docker.com/desktop/linux/).

You'll need to be in the `demo2` directory.

_Check your setup:_

```
kubectl get nodes

pwd
```

## Losing data during updates

The Products database uses Postgres. It's fine to run a containerized database in non-production environments, but you'll typically want data preserved between updates.

Our initial deployment has no volume mounts so the data files are stored in the container writeable layer:

```
kubectl apply -f ./preprod/
```

The database container is pre-populated with data, and we can read and update it using the Stock API:

```
curl http://localhost:8090/stock/1

curl -X PUT http://localhost:8090/stock/1 -d '{\"stock\" : 0}'

curl http://localhost:8090/stock/1
```

[This Deployment](./db-update/products-db.yaml) updates to a more recent Postgres version:

```
kubectl apply -f ./db-update/

kubectl get po -l component=products-db --watch

kubectl exec deploy/products-db -- ls /var/lib/postgresql/data 
```

> There's still data in the directory of the new Pod, but it's just the initialized data.

Try the Stock API again and we'll see the updates are gone:

```
curl http://localhost:8090/stock/1
```

## Requesting storage with Persistent Volume Claims

This spec reverts back to the original Postgres version, but with a PVC mounted to the storage location:

- [pvc/products-db.yaml](./pvc/products-db.yaml) - creates a PVC requesting 100MB of storage and mounts it to the data folder

Now data will be stored outside of the Pod:

```
kubectl apply -f ./pvc/
```

Update the stock for a product to persist a change:

```
curl -X PUT http://localhost:8090/stock/1 -d '{\"stock\" : 0}'

curl http://localhost:8090/stock/1
```

Now we can update the database:

- [pvc-db-update/products-db.yaml](./pvc-db-update/products-db.yaml) - updates the Postgres version but uses the same PVC

```
kubectl apply -f ./pvc-db-update/

kubectl get po -l component=products-db --watch
```

The new Pod attaches the same storage, so the data changes are still there:

```
curl http://localhost:8090/stock/1
```


## Storage Classes and provisioners

The PVC just requested some storage - Kubernetes created a Persistent Volume to provide the storage:

```
kubectl get pvc,pv
```

Persistent Volumes are an abstraction over storage. They use the same volume plugin system as volumes attached to Pods, but they have their own lifecycle:

```
kubectl describe pv
```

How did the cluster know to create a HostPath volume? Storage capabilities differ between Kubernetes implementations, and they're defined in Storage Classes:

```
kubectl get storageclass
```

Docker Desktop has a single Storage Class, which uses the HostPath provisioner. That can create a volume which is just a directory on the node's disk.

Bare-metal Kubernetes clusters may not have any provisioners:

```
kubectl config use-context sixeyed

kubectl get sc
```

> This is my home cluster built without any dynamic storage capabilities.

Cloud clusters will integrate with the cloud's storage services:

```
kubectl config use-context ps-aks-m4

kubectl get storageclass
```

> A cluster in Azure can use a variety of Azure Disk and Azure Files storage.
