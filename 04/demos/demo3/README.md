
# Managing Persistent Volumes

- Explicitly specifying Persistent Volumes
- Configuring Persistent Volumes without a provisioner
- Utilizing cluster-wide storage

## Pre-requisites

You just need Kubernetes for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Desktop on Linux](https://docs.docker.com/desktop/linux/).

You'll need to be in the `demo3` directory.

_Check your setup:_

```
kubectl get nodes

pwd
```

## Explicitly specifying Persistent Volumes

If your cluster doesn't support dynamic provisioners, or you want more control over your volumes, you can include them in your application model.

We'll start with a deployment which doesn't use volumes to get the app running:

```
kubectl apply -f ./preprod/
```

And test the app is working with the default data set:

```
curl http://localhost:8090/stock/1
```

Now we'll update the Products database to use a PVC:

- [pv/products-db.yaml](./pv/products-db.yaml) - specifies a PV using a local volume, which stores data in a set path on the node; it includes a node selector which pins the PV to a specific node

Create the PV and PVC, and update the database spec:

```
kubectl apply -f ./pv/

kubectl get pv,pvc
```

The PVC starts in the `Pending` state, when it's bound we can check the database Pods:

```
kubectl get pvc --watch

kubectl get po -l component=products-db
```

> The new Pod which uses the PVC is stuck in the `ContainerCreating` state.

Print the details of the Pod to see why the container isn't running:

```
kubectl describe po <id>
```

> There's a `FailedMount` error, saying the path for the local volume doesn't exist.

## Configuring Persistent Volumes without a provisioner

When you manually create PVs, there may be extra steps in the underlying storage - e.g. creating an NFS share, or in this case creating a folder path.

Open a new terminal so we can watch the new Pod and see its status change:

```
kubectl get po -l component=products-db,storage=hostpath --watch
```

This spec for a jumpbox Pod has full read/write access to the root folder on the node:

- [jumpbox/pod.yaml](./jumpbox/pod.yaml) - giving a Pod full access to the node's filesystem is not a great idea

Create the Pod and connect to a shell session:

```
kubectl apply -f ./jumpbox/

kubectl exec -it jumpbox -- sh
```

We can explore the node's disk and create the missing path for the PV:

```
ls /node-root

mkdir -p /node-root/volumes/products-db

exit
```

> The Producsts DB Pod keeps retrying, and it will start as soon as the retry finds the local volume path exists.

Our PV has a node selector. Any Pods using that PV will be scheduled onto the same node:

```
kubectl get po -o wide
```

We only have one node, but the Pod will follow the PV even in a multi-node cluster.

## Utilizing cluster-wide storage

Local volumes can only be used in `ReadWriteOnce` mode, meaning many Pods can access the volume but only if they're all running on the same node - the storage unit cannot be mounted to multiple nodes.

Cluster-wide storage supports `ReadWriteMany` mode, so Pods on different nodes can attach the same volume. That's for shared storage like NFS or cloud services.

We'll switch to a multi-node cluster in Azure for this part of the demo (see the documentation in [AKS](./aks.md) for the create commands):

```
kubectl config use-context ps-aks-m4

kubectl get nodes
```

The Products API can be configured to write logs to a file. We may want log files from all Pods written to a single storage location which we can use to aggregate them. 

Azure Files is cluster-wide storage which we can use for that:

- [azurefiles/products-api.yaml](./azurefiles/products-api.yaml) - specifies a PVC with an Azure Files Storage Class, which is mounted to the log file location on the Pod

We'll start by running the app with a single Pod for the Products API:

```
kubectl apply -f ./preprod/ -f ./azurefiles/
```

Creating the PVC will cause the provisioner to allocate storage and assign it to the PV:

```
kubectl describe pv
```

The Products API writes log entries as soon as it starts. Listing the log files will show one file, containing the Pod name:

```
kubectl exec deploy/products-api -- ls /app/logs
```

Now if we scale up, the new Pods will all use the same storage location - even if they're running on different nodes:

```
kubectl scale deploy/products-api --replicas 5

kubectl get po -l component=products-api -o wide
```

And if we list the log files we'll see one file from each Pod:

```
kubectl exec deploy/products-api -- ls /app/logs
```

> Browse to https://portal.azure.com to see the Azure Files share.

