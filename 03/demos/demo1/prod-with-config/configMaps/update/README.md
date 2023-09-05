## ConfigMaps in Kubernetes

- Default settings in the image
- Applying settings with ConfigMaps
- Understanding change propagation

## Pre-requisites

You just need Docker for this demo, and the course downloads. Install [Docker Desktop](https://www.docker.com/products/docker-desktop) on Mac or Windows, or [Docker Desktop on Linux]().

You'll need to be in the `demo1` directory.

_Check your setup:_

```
docker version

pwd
```

# Default settings in the image

The Widgetario applicaion is distributed across four containers which we have modelled in Kubernetes Deployments and Services:

- [Products DB](./dev/products-db.yaml) - the application database
- [Products API](./dev/products-api.yaml) - product list API
- [Stock API](./dev/stock-api.yaml) - stock management API
- [Website](./dev/web.yaml) - public web application

The Docker images are built with default configuration settings so we can run without any volume mounts:

```
kubectl get all

ls ./dev

kubectl apply -f ./dev
```

Kubernetes will create 4 Pods and 4 Services:

```
kubectl get po,svc
```

> Browse to http://localhost:8088

# Applying settings with ConfigMaps

The app is working fine, but for the production environment we need to make changes to match the object naming conventions:

- compare [dev Products DB](./dev/products-db.yaml)  and [production Products DB](./prod/products-db.yaml)
- compare [dev Products API](./dev/products-api.yaml)  and [production Products DB](./prod/products-api.yaml)

If we deploy this spec we'll have problems:

```
kubectl delete -f ./dev

kubectl apply -f ./prod
```

We'll have 4 new Pods and 4 new Services:

```
kubectl get po,svc
```

> Browse to http://localhost:8088 - now it's broken

Let's debug:

```
kubectl logs -l component=web

kubectl exec -it deploy/web -- sh
```

Inside the container, we can check configuration and connectivity:

```
ls

cat appsettings.json # localhost

printenv | grep Url

nsloookup products-api

exit
```

> We'lll have the same problem with the APIs too, the Service name no longer matches the default config

# Loading configuration from ConfigMaps

The Web and Products API can load configuration from the filesystem:

- [web-config-api.yaml](.\prod-with-config\configMaps\web-config-api.yaml) - sets the correct URLs and environment name in a JSON config file
- [web.yaml](.\prod-with-config\web.yaml) - loads the config JSON from the ConfigMap to the expected file path
- [products-api-config-db.yaml](\prod-with-config\configMaps\products-api-config-db.yaml) - sets the database connection details in a properties file
- [products-api.yaml](.\prod-with-config\products-api.yaml) - loads the properties file into the container filesystem

The Stock API is different, because it only looks in environment variables for configuration:

- [stock-api-config-db.yaml](.\prod-with-config\configMaps\stock-api-config-db.yaml) - sets the database connection in a key-value pair
- [stock-api.yaml](.\prod-with-config\stock-api.yaml) - loads the ConfigMap settings as environment variables

Deploy the configuration:

```
kubectl apply -f .\prod-with-config\configMaps\

kubectl get cm -l app=wiredbrain
```

Deploy changes:

```
kubectl apply -f .\prod-with-config\

kubectl get po
```

Check the web app is loading the correct config:

```
kubectl exec deploy/web -- cat /app/secrets/api.json
```

> Try the app at http://localhost:8088 - working again with pre-prod settings

# Understanding change propagation

ConfigMap contents can't be changed from the container, but they can be changed in Kubernetes:

- 
change PROD in web config

check web

check file

k exec deploy/web -- cat /app/secrets/api.json

- Changes are there; check code

D:\scm\psod\psod-storage-2022\psod-storage-2022-source\m3\src\web\src\WiredBrain.Web\Program.cs

reloadOnChange: true

This framework looks for the file changed date. That doesn't change because it's a symlink:

k exec deploy/web -- ls -l /app/secrets/

> The container filesystem doesn't necessarily work the way your app expects