# Images and image layers

- Running containers from images
- Building images from base images
- Exploring the layer hierarchy

## Pre-requisites

You just need Docker for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Engine]() on Linux.

You'll need to be in the `demo1` directory.

_Check your setup:_

```
docker version

pwd
```

## Running containers from images

_Run a simple web server, connecting to a shell session:_

```
docker run -it --rm nginx:1.21.6-alpine sh
```

> This is an interactive container, we've overridden the default startup command

_Explore the container filesystem:_

```
ls /

cat /docker-entrypoint.sh

dig blog.sixeyed.com

nslookup blog.sixeyed.com

which nginx

exit
```

> Some standard tools are available, from the Alpine base; other content is from Nginx

_List all containers:_

```
docker ps -a
```

> Nothing there - the `rm` flag means Docker removes the container when it exits. The filesystem is gone.


_Inspect the image:_

```
docker image ls nginx 

docker inspect nginx:1.21.6-alpine
```

> Multiple image layers; the first is the Alpine OS layer, the ID starts `8d3`

_Inspect the base Alpine OS image:_

```
docker pull alpine:3.15

docker inspect alpine:3.15
```

> Just a single layer, this is the same `8d3` layer the Nginx image uses

_Check storage use:_

```
docker image ls

docker system df
```

> 23.4MB of storage; image size is the virtual size

## Building images from base images

We'll build a simple image:

- [Dockerfile](./Dockerfile) - builds on the Alpine image
- [hello.txt](./hello.txt) - text file which is copied to the image

_Build the image:_

```
ls

docker build -t hello:alpine .

docker run hello:alpine
```

> The container just prints the file contents and exits

_Run an interactive container and explore the filesystem:_

```
docker run -it --rm hello:alpine sh

nslookup blog.sixeyed.com

which nginx

ls -l

exit
```

> The same OS tools as the Nginx image, but without Nginx and with the extra text file

_Inspect the image:_

```
docker inspect hello:alpine
```

> It uses the same `8d3` base layer; the second layer is the text file

_Check storage again:_

```
docker image ls 

docker system df
```

