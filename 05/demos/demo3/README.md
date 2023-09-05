# Cleaning up image storage

- Pruning Docker servers
- Pruning Kubernetes nodes

## Pre-requisites

You just need Kubernetes for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/get-started/) on Mac, Windows or Linux.

You'll need to be in the `demo3` directory.

_Check your setup:_

```
kubectl get nodes

pwd
```

To follow along with the AKS examples, you'll need an Azure subscription.

## Pruning Docker servers

Keeping your disks clean is easy enough with Docker, but you'll need to choose the right command to run in each environment.

In a production or non-production server where you're running apps, you can clear down dangling images safely:

```
docker image prune -f
```

You can also remove all *unused* images, which means any images which aren't currently being used to run containers:

```
docker image prune --all -f
```

This is also safe - it won't stop any running containers - but you could remove images you'll want to use again. They'll need to be pulled next time you use them.

On a build server you'll want to regularly prune the build cache:

```
docker builder prune -f
```

You can do this safely, it doesn't affect containers or images. But it will reset all your build cache, so the next set of builds will be slower.

In a dev environment where you want to clear everything down, start by removing all containers and then prune the whole system:

```
docker rm -f $(docker ps -aq)

docker network prune -f

docker system prune -af --volumes
```

> Be warned, this gets rid of everything :)

## Pruning Kubernetes nodes

Remote container platforms typically don't give you access to the underlying nodes, and they don't always use Docker as the container runtime.

You need to take a different approach to clean up a Kubernetes node, using [crictl](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/) - the CLI for any implementation of the Container Runtime Interface.

---
_Kubernetes has a garbage collection mechanism so you shouldn't need to prune images. By default it fires when the node's disk is 80% full disk, but is can be tuned in the Kubelet configuration._

---

But if you do want to clean up images, you can use a Kubernetes Job to run a `crictl` command:

- [prune-images.yaml](./prune-images.yaml) - uses a container image with `crictl` installed, mounting the containers socket and running the prune command

This spec only works on clusters which use containerd as the container runtime.

My Docker Desktop istance is configured to use Docker:

```
kubectl apply -f ./prune-images.yaml
```

The Pod gets created, but it fails to run:

```
kubectl get po -l job-name=prune-images

kubectl describe po -l job-name=prune-images
```

> You only need to dig into the container runtime in specific scenarios - usually you can stick to modelling your app in YAML and leaving it to Kubernetes and the CRI

My [AKS](./aks.md) cluster is using containerd, so this prune Job will run:

```
kubectl config use-context ps-aks-m5

kubectl get nodes
```

The Job will only run on one node, but it could be extended with multiple completions and affinity to spread Pods onto each node:

```
kubectl apply -f ./prune-images.yaml

kubectl get po -l job-name=prune-images --watch
```

On this cluster the Pod runs correctly. Check the logs:

```
kubectl logs -l job-name=prune-images
```

> Hmm. There are important-sounding images in the list. Perhaps we should leave this to the garbage collector after all...