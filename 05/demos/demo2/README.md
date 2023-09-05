
## Managing Container Registries

- Tagging & pushing images
- Inspecting remote images
- Scripting registry cleanup

## Pre-requisites

You just need Docker for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/get-started/) on Mac, Windows or Linux.

You'll need to be in the `demo2` directory.

_Check your setup:_

```
docker version

pwd
```

To follow along with the ACR examples, you'll need an Azure subscription.

## Tagging & pushing images

To push images to a custom registry, you need to include the registry domain in the image reference. You can be flexible with that using Docker Compose for your builds:

- [docker-compose.yml](../src/wiredbrain/docker-compose.yml) - uses environment variables with defaults to set the registry domain and image tag

- [edit-and-build-tagged.ps1](./edit-and-build-tagged.ps1) - sets the environment to use the WiredBrain container registry in Azure.

Clean all local images and build some new images to push:

```
docker image prune -af

./edit-and-build-tagged.ps1

./edit-and-build-optimized.ps1
```

We now have a set of storage-optimized and a set of unoptimized web images, tagged with the ACR domain name:

```
docker image ls
```

Right now the ACR instance has no images:

```
az acr repository list -n wiredbrain
```

When we push we'll see how the layers get cached in the registry server too:

```
az acr login -n wiredbrain

docker image push --all-tags wiredbrain.azurecr.io/wiredbrain/web
```

> The optimized images only need a 4MB layer upload for each tag


## Inspecting remote images

Private registries have their own management tools. ACR uses the AZ command line:

```
az acr repository list -n wiredbrain

az acr repository show-tags -n wiredbrain --repository wiredbrain/web
```

But they also support standard OCI image features. You can inspect the manifest of a remote image, which reports the layers and their size.

Compare two of the unoptimized web images:

```
docker manifest inspect wiredbrain.azurecr.io/wiredbrain/web:22.05-m5-3 | jq '.layers'

docker manifest inspect wiredbrain.azurecr.io/wiredbrain/web:22.05-m5-1 | jq '.layers'
```

Each image has 6 layers, 5 are shared and the last layer - which is the application folder - is 2MB compressed.

And compare two of the optimized images:

```
docker manifest inspect wiredbrain.azurecr.io/wiredbrain/web:22.05-m5-optimized-3 | jq '.layers'

docker manifest inspect wiredbrain.azurecr.io/wiredbrain/web:22.05-m5-optimized-1 | jq '.layers'
```

Each has 8 layers, with 7 shared, and the last layer - which is just the WiredBrain binaries - is 1MB compressed.


## Scripting registry cleanup

Optimizing your images is important when you're paying for storage in a registry server, but you also need a regular cleanup feauture.

I've already run this script to simulate a busy period at WiredBrain, with lots of images built and pushed:

- [fill-registry.ps1](./fill-registry.ps1) - builds 40 images for each component and pushes them with versioned tags and with a `latest` tag.

> Check the ACR at https://portal.azure.com

This could represent 1 week of development, and it's already using 3% of the alloted storage...

Typically you only want to keep the release image - `:latest` or `:v1` or `:22.05` - and a few of the most recent builds

This script clears down all the older tags using the `az` command. There's no Docker functionality to manage images on remote registries, so you need to use the tools from your platform:

- [prune-registry.ps1](./prune-registry.ps1) - removes all but the 3 most recently-pushed tags and the `latest` tag for each repository

```
./prune-registry.ps1
```

When that completes, the registry is using less than 0.5% of its storage.