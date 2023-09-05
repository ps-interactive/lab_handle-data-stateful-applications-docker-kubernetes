# RBAC Setup

This creates two sets of permissions for different user groups, and a user for each group. You can create a Kubectl context for each user and switch between them to verify their permissions.

## Deploy the RBAC rules

```
kubectl apply -f rbac/
```

Verify the permissions with `can-i`, using the group name and any username.

_SREs are allowed to work with Secrets and Pods:_

```
kubectl auth can-i get pods -n default --as-group sre --as unknown

kubectl auth can-i get secrets -n default --as-group sre --as unknown
```

_Testers can only get Pods:_

```
kubectl auth can-i get pods -n default --as-group tester --as unknown

kubectl auth can-i get secrets -n default --as-group tester --as unknown
```

## Create the user certificates

I use a tool to generate client certificates which are approved by the Kubernetes API. The actual certs are created in Kubernetes Jobs for two users:

```
kubectl apply -f users/
```

Check the Pods and you should see they're completed:

```
kubectl get po -n users
```

Print the Pod logs and copy the certificate contents - you'll need a `user.crt` and a `user.key` file for each user:

```
kubectl logs -n users -l job-name=sre-user --tail 50

kubectl logs -n users -l job-name=test-user --tail 50
```

> There are some example files in the `certs` folder so you can check the format, but these **will not work with your cluster**. You need to use your own certs, which have been approved by your Kubernetes cluster.


## Create Kubectl users

Use the certs files to create the user:

```
kubectl config set-credentials siobhan --client-key=certs/siobhan/user.key --client-certificate=certs/siobhan/user.crt --embed-certs=true

kubectl config set-context siobhan --namespace default  --user=siobhan --cluster docker-desktop
```

And the test user:

```
kubectl config set-credentials rishi --client-key=certs/rishi/user.key --client-certificate=certs/rishi/user.crt --embed-certs=true

kubectl config set-context rishi --namespace default --user=rishi --cluster docker-desktop
```

Now you can switch users with `kubectl config use-context siobhan` and `kubectl config use-context rishi` to test permissions.