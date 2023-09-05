## Volumes and filesystem mounts

- Using Docker volumes
- Mounting host directories
- Mounts in Windows containers

## Pre-requisites

You just need Docker for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Engine]() on Linux.

You'll need to be in the `demo3` directory.

_Check your setup:_

```
docker version

pwd
```

## Using Docker volumes

Volumes are first-class objects in Docker, they exist independently of any containers using them.

_Create a new volume:_

```
docker volume create demo3

docker volume ls

docker volume inspect demo3
```

> The `Mountpoint` is the storage location on the host - on Linux you can navigate to that directory from the host

_Run a container using the volume:_

```
docker run -it --rm -v demo3:/mnt/vol alpine:3.15

touch /mnt/vol/file1.txt

touch /file2.txt

find / -name "*.txt"

exit
```

> The container is gone, but the data is still in the volume

_Print containers and volumes:_

```
docker ps -a

docker volume ls
```

_Run a new container from a different image, attaching the same volume:_

```
docker run -it --rm -v demo3:/mnt/vol debian:11.2-slim

find / -name "*.txt"

exit
```

> The new container sees the data written from the previous container

## Mounting host directories

The volume `-v` argument can also be used to _bind mount_ a directory from the host - so the container can access files on the machine running the container.

_Run a container with a mount to the local `docs` folder:_

```
ls

echo "$($pwd)/docs"

docker run -it -v "$($pwd)/docs:/mnt/docs" alpine:3.15

ls /mnt/docs
```

> The bind mount adds new folder in the container filesystem

_Read and write data from the mounted folder:_

```
cat /mnt/docs/hello.txt

echo ' Yes' >> /mnt/docs/hello.txt

exit

hostname

cat ./docs/hello.txt
```

> The mount is readable and writeable from the host and the container

_Run a container with a single file as a bind mount:_

```
docker run hello:alpine

docker run -v "$($pwd)/docs/hello.txt:/hello.txt" hello:alpine
```

> The mount hides the file from the image layers

Directory mounts also hide any existing directories - **they are not merged**.

_Run a plain Nginx web server:_

```
docker run -d -p 8081:80 --name nginx1 nginx:1.21.6-alpine

curl localhost:8081

docker exec nginx1 ls /usr/share/nginx/html
```

> The HTML content is from the image layers

_Run another container with a mount to serve custom content:_

```
ls ./html

docker run -d -p 8082:80 --name nginx2 -v "$($pwd)/html:/usr/share/nginx/html" nginx:1.21.6-alpine
 
curl localhost:8082

docker exec nginx2 ls /usr/share/nginx/html
```

> There is no `50x.html` file - the whole folder is replaced with the mount

## Mounts in Windows containers

Docker Desktop on Windows supports Linux and Windows containers - switch to Windows from the taskbar menu.

_Check the containers:_

```
docker version

docker ps -a

docker volume ls

curl localhost:8082
```

> This is a separate Docker engine - the other containers are still running on the Linux Docker engine

_Run a Windows OS container:_

```
docker run -it mcr.microsoft.com/windows/servercore:20H2 powershell

ls /

ls /Windows

exit
```

> This is a standard(ish) Windows Server installation


_Run a Windows container with a bind mount:_

```
docker run -it -v "$($pwd)/docs:C:\mnt\docs" mcr.microsoft.com/windows/servercore:20H2 powershell

ls /

cat /mnt/docs/hello.txt

exit
```

> Bind mounts work in the same way - Docker takes care of managing different filesystems

_Run a Windows web server:_

```
docker run -d -p 8083:80 --name iis mcr.microsoft.com/windows/servercore/iis:windowsservercore-20H2

curl localhost:8083

docker exec iis powershell "ls /inetpub/wwwroot"
```

> This is the standard IIS content

_Now run IIS with the same custom HTML we used for Nginx:_

```
docker run -d -p 8084:80 -v "$($pwd)/html:C:\inetpub\wwwroot" --name iis2  mcr.microsoft.com/windows/servercore/iis:windowsservercore-20H2

curl localhost:8084

docker exec iis2 powershell "ls /inetpub/wwwroot"
```

> The home directory from the image layer gets replaced with the bind mount, just like in Linux

_But Windows containers can't mount a single file:_

```
# this will fail
docker run -v "$($pwd)/html/index.html:C:\inetpub\wwwroot\index.html"  mcr.microsoft.com/windows/servercore/iis:windowsservercore-20H2
```

> This is the big difference with mounts in Windows containers - directories only, not files