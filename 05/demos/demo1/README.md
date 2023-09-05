# Optimizing Storage in Docker Builds

- Understanding dangling images
- Optimizing builds for speed
- Optimizing builds for storage

## Pre-requisites

You just need Docker for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/get-started/) on Mac, Windows or Linux.

You'll need to be in the `demo1` directory.

_Check your setup:_

```
docker version

pwd
```

I'm starting with an empty image cache.

## Dangling images

Docker is very conservative with data - it doesn't delete anything unless you tell it to. When you make changes to code and rebuild an image, the old image layers aren't removed:

- [edit-and-build.ps1](./edit-and-build.ps1) - simulates changing source and rebuilding with the same image tag

Run the script to create some images:

```
./edit-and-build.ps1
```

Check the images:

```
docker image ls
```

>  Those `<none>` entries are _dangling images_. You can run containers from them using the image ID, but they don't have a tag because the tag has been replaced by the later build.

It's safe to delete those dangling images, which is what the default `prune` command does:

```
docker image prune

docker image ls
```

Now only tagged images remain.

You might still have lots of storage being used in the build cache:

```
docker system df
```

You can clear that with a specific command:

```
docker builder prune
```

> I've had 10s of GB taken up in build cache on some of my machines...


## Optimized builds for speed

The last set of builds used a pretty well organized Dockerfile, taking about 3s each time on my machine.

That's after optimization though. Here's how it is before optimizing:

- [Dockerfile.slow](../src/wiredbrain/web/Dockerfile.slow) - a multi-stage .NET build, ready for optimizing

Loading libraries is typically a slow part of the build, let's see the impact from not caching that step:

```
./edit-and-build-slow.ps1
```

> Build times are up by 30%, sometimes longer if the network is busy

Most platforms let you split out the library step, so you can copy the dependency list and run the restore first. Then if your dependencies don't change, the libraries come from the cache:

- [Dockerfile](../src/wiredbrain/web/Dockerfile) - the optimized multi-stage .NET build


## Optimized builds for storage

Images which build quickly don't necessarily make the best use of storage, so there could be some more optimizing to do.

Let's clear out all the images to start with:

```
docker image prune -af
```

And build a set of images with incrementing build numbers in the tag, like in a CI/CD pipeline:

```
./edit-and-build-tagged.ps1
```

> This script is using the speed-optimized Dockerfile, so each build takes about 3s on my machine

These images are all different IDs with different tags:

```
docker image ls
```

If the IDs are different, the layers must diverge:

```
docker image inspect wiredbrain/web:22.05-m5-3 | jq '.[].RootFS.Layers'

docker image inspect wiredbrain/web:22.05-m5-1 | jq '.[].RootFS.Layers'
```

> There are 5 shared layers; only the final layer - which contains the build output - is different

Inspecting the image tells use the layer hash but not the size. We can get that from the history:

```
docker history wiredbrain/web:22.05-m5-3
```

The application layer is 9 MB, which means every build will have a different 9MB layer. That 9MB contains the application binaries - most of which are libraries which don't change often:

```
docker run -it --entrypoint sh wiredbrain/web:22.05-m5-3 -c "ls -l /app"
```

The WiredBrain binaries are a minority of the space. This Dockerfile splits the app layer into multiple layers, allowing the library layer to be shared:

- [Dockerfile.optimized](../src/wiredbrain/web/Dockerfile.optimized) - breaks the output into separate `COPY` instructions

The build will still be fast, but now the output images can share more layers:

```
./edit-and-build-optimized.ps1
```

Compare the images layers from the original and the optimized versions:

```
docker image inspect wiredbrain/web:22.05-m5-3 | jq '.[].RootFS.Layers'

docker image inspect wiredbrain/web:22.05-m5-optimized-3 | jq '.[].RootFS.Layers'
```

Breaking one large layer into smaller layers means you make better use of the cache:

```
docker image inspect wiredbrain/web:22.05-m5-optimized-1 | jq '.[].RootFS.Layers'
```

Only the top layer is different in the optimzed v1 and v3 builds, but this layer is much smaller:

```
docker history wiredbrain/web:22.05-m5-optimized-3
```

4MB instead of 9MB. This might be a micro-optimization in this example, but an app layer with 200MB of binaries would definitely benefit from this approach.
