# Persistent Storage in Kubernetes

- Data in the container writeable layer
- Pod-level storage with EmptyDir
- Working with read-only filesystems

## Pre-requisites

You just need Kubernetes for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Desktop on Linux](https://docs.docker.com/desktop/linux/).

You'll need to be in the `demo1` directory.

_Check your setup:_

```
kubectl get nodes

pwd
```

## Data in the container writeable layer

Containers have a writeable filesystem, but it has the same lifecycle as the container - any changes that are written will be gone when the container is replaced.

We'll deploy a new version of the app where the Stock API caches items from the database:

```
kubectl apply -f ./preprod/
```

> Check the app is working at http://localhost:8088 & refresh.

We can verify that the Stock API is caching data locally:

```
kubectl logs -l component=stock-api

kubectl exec deploy/stock-api -- ls /cache
```

The `/cache` folder isn't a volume mount, so the data is stored in the container writeable layer.

Let's see what happens when we simulate an application crash:

```
kubectl exec deploy/stock-api -- kill 1

kubectl get po -l  component=stock-api
```

> Killing the application process means the container exits - the Pod restarts by creating a new container.

The new container has a new writeable layer. The cache files written by the old container are lost:

```
kubectl exec deploy/stock-api -- ls /cache
```

It's empty. The app is still working, but we'll have lost performance.

## Pod-level storage with EmptyDir

The simplest storage option in Kubernetes is the EmptyDir volume:

- [emptydir/stock-api.yaml](./emptydir/stock-api.yaml) - mounts an EmptyDir volume to the `/cache` directory

This is Pod-level storage which is managed by Kubernetes. EmptyDir volumes start off as an empty directory; they can be mounted in containers and any data written has the lifecycle of the Pod, not the containers.

Update the spec to use EmptyDir:

```
kubectl apply -f ./emptydir

kubectl wait --for=condition=Ready pod -l component=stock-api,storage=emptydir

kubectl get pod -l component=stock-api
```

We have a new Pod, which starts out with an empty cache directory.

Use the app and we'll see the cache loading:

```
curl http://localhost:8088 

kubectl exec deploy/stock-api -- ls /cache
```

Now when the application in the container crashes, the Pod restarts with a new container which mounts the same EmptyDir volume: 

```
kubectl exec deploy/stock-api -- kill 1

kubectl get po -l component=stock-api

kubectl exec deploy/stock-api -- ls /cache
```

> Replacement containers can read the cache files written by previous containers.


## Working with read-only filesystems

One other use for EmptyDir is to provide some writeable storage for a container which is configured to use a read-only filesystem:

- [readonlyfs/stock-api.yaml](./readonlyfs/stock-api.yaml) - uses a read-only filesystem with no volumes

This is a useful security feature, but not all apps support it. The Stock API is a Go application which can run with a read-only filesystem, but the caching feature won't work.

Update the deployment:

```
kubectl apply -f ./readonlyfs

kubectl wait --for=condition=Ready pod -l component=stock-api,storage=readonly
```

Try the app and check the logs:

```
curl http://localhost:8088 

kubectl logs -l component=stock-api
```

> The app works, but the cache fails so we will have a performance issue.

EmptyDir volume mounts provide a writeable location in a read-only filesystem:

- [readonlyfs-emptydir/stock-api.yaml](./readonlyfs-emptydir/stock-api.yaml) - uses a read-only filesystem with an EmptyDir volume for the cache

```
kubectl apply -f ./readonlyfs-emptydir

kubectl wait --for=condition=Ready pod -l component=stock-api,storage=readonly-with-emptydir
```

Now the cache works again, but the rest of the filesystem is read-only:

```
curl http://localhost:8088 

kubectl logs -l component=stock-api

kubectl exec deploy/stock-api -- ls /cache

kubectl exec deploy/stock-api -- touch /app/hack.py
```