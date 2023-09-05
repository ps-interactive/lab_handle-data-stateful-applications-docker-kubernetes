# Container writeable layers

- Editing data in containers
- Container lifecyle
- Data lifecycle

## Pre-requisites

You just need Docker for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Engine]() on Linux.

> If you want to inspect the container filesystem from the host machine, you'll need Docker Engine on Linux.

You'll need to be in the `demo2` directory.

_Check your setup:_

```
docker version

pwd
```

## Editing data in containers

We'll build a new image with a bit more flexibility:

- [Dockerfile](./Dockerfile) - builds on the Alpine image and runs a shell script at startup
- [start.sh](./hello/start.sh) - script prints text file content and sleeps
- [hello.txt](./hello/hello.txt) - text file which is copied to the image

_Build the image:_

```
ls

docker build -t hello:2 .
```

_Run a container from the image:_

```
docker run -d --name h1 hello:2

docker ps

docker logs h1
```

_Connect to the container and edit the text file:_

```
docker exec -it h1 sh

cat /hello.txt

echo Hello Pluralsight > /hello.txt

cat /hello.txt

exit
```

## Container lifecyle

The main statuses of a container are `Running` and `Exited`. In both states the filesystem is preserved, including the writeable layer.

_Stop and restart the container:_

```
docker stop h1

docker ps -a 

docker start h1

docker logs h1
```

> Container filesystem isn't removed when it's stopped, so the changed contents are printed when it restarts


_Run another container from the same image:_

```
docker run -it --name h2 hello:2

# Ctrl-C to exit
```

> The changes in one container don't affect the Docker image

## Data lifecycle

_Inspect the first container:_

```
docker ps -a

docker inspect h1
```

> GraphDriver.Data is a path in `/var/lib/docker/overlay2/`; you can't see it in Docker Desktop

_You can see it if you switch to Docker on Linux:_

```
# in a new WSL session

docker version

docker run -d --name h1 sixeyed/hello:2

docker exec -it h1 sh

cat /hello.txt

echo Hello Pluralsight > /hello.txt

exit
```

> Now we have an identical container in a separate engine

```
docker inspect h1

docker inspect h1 --format '{{.GraphDriver.Data.UpperDir}}'

dir=$(docker inspect h1 --format '{{.GraphDriver.Data.UpperDir}}')

sudo ls -l $dir

sudo cat "$dir/hello.txt"
```

> There's the changed file - it gets merged into the container FS

_Remove the container:_

```
docker rm -f h1

sudo ls -l $dir
```

> Writeable layer and contents are gone forever!