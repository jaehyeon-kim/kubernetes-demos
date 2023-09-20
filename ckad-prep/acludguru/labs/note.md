## 1. Using Multiple Containers in a Kubernetes Pod

Welcome to HiveCorp, a software design company that is totally not run by bees! Your team is working on part of the company's honey management app. Sorry, money management, not honey management!

Your app reaches out to a Service maintained by another team. Some recent changes by the other team have led to some issues:

- Your team's app Pods need to delay startup by a few seconds to allow time for some auxiliary systems to react to the Pod's presence.
- The other team wants to change the external Port exposed by their Service, and your team's app will need to be updated accordingly. Use an ambassador container so that this port is more easily configurable in the future.

Solve these problems by modifying your app's Deployment. Use an init container to delay your app's startup, and use an ambassador container to allow your app to use the new Service port in a configurable way.

1. Update the Service to Use the New Port

There is a Service called hive-svc located in the default Namespace. Modify this service so that it listens on port 9076

2. Add an init Container to Delay Startup

The app is managed by the app-gateway Deployment located in the default Namespace. Add an init container to the Pod template so that startup will be delayed by 10 seconds. You can do this by using the busybox:stable image and running the command sh -c sleep 10.

3. Add an Ambassador Container to Make the App Use the New Service Port

Find the app-gateway Deployment located in the default Namespace. Add an ambassador container to the Deployment's Pod template using the haproxy:2.4 image.

Supply the ambassador container with an haproxy configuration file at /usr/local/etc/haproxy/haproxy.cfg. There is already a ConfigMap called haproxy-config in the default Namespace with a pre-configured haproxy.cfg file.

You will need to edit the command of the main container so that it points to localhost instead of hive-svc.

## 2. Using Container Volume Storage in Kubernetes

Welcome to HiveCorp, a software design company that is totally not run by bees!

Our company is always working to store things, mainly honey. Don't ask why! But right now, we just need to handle storing some data for our containers.

The application needs 2 forms of storage:

An ephemeral storage location to store some temporary data outside the container file system.
A Persistent Volume that utilizes a directory on the local disk of the worker node.
Modify the application's deployment to implement these storage solutions.

1. Add an Ephemeral Volume

The application is managed by the app-processing Deployment in the default Namespace.

The application needs to write some temporary data, but it cannot write directly to the container file system because it is set as read-only. Use a volume to create a temporary storage location at /tempdata.

2. Add a Persistent Volume

The application is managed by the app-processing Deployment in the default Namespace. Use a PersistentVolume to mount data from the k8s host to the application's container. The data is located at /data/hivekey.txt on the host. Set up the PersistentVolume to access this data using directory mode.

For the PersistentVolume, set a capacity of 1Gi. Set the access mode to ReadWriteOnce, and set the storage class to host.

For the PersistentVolumeClaim, set the storage request to 100Mi. Mount it to /data in the container.

Note: The application is set up to read data from the PersistentVolumeClaim's mounted location, then write it to the ephemeral volume location, and read it back from the ephemeral volume to the container log. This means that if everything is set up properly, you see the Hive Key data in the container log!

```sh
minikube ssh
sudo su
echo "000000000" > /data/hivekey.txt
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: host
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
spec:
  storageClassName: host
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

## 3. Advanced Rollout with Kubernetes Deployments

Welcome to HiveCorp, a software design company that is totally not run by bees!

We need to ship some new software versions for our Kubernetes applications!

There is a web frontend application that needs to be updated to a new version. Since this application is customer-facing, use a rolling update to roll out the new version with zero service interruptions.

We also have an internal API that needs to be updated. The team is concerned about some stability issues that have occurred during past Deployments, leading to lost productivity. Use a blue/green Deployment strategy to test the new version and ensure that it is working before directing user traffic to it.

1. There is a Deployment in the hive Namespace called web-frontend.

Update the image used in the Deployment's Pod to nginx:1.16.1.

2. There is a Deployment in the hive Namespace called internal-api-blue.

A Service called api-svc directs traffic to this Deployment's Pods.

You can find a YAML manifest for the Deployment at /home/cloud_user/internal-api-blue.yml. Make a copy of this manifest at /home/cloud_user/internal-api-green.yml. Modify the manifest to create a green Deployment called internal-api-green. For the green Deployment, use the image linuxacademycontent/ckad-nginx:green.

Update the Service to point only to the green Deployment's Pods.

```bash
k set image deploy web-frontend nginx=nginx:1.16.1 -n hive --record
```

## 4. Deploying Packaged Kubernetes Apps with Helm

Welcome to HiveCorp, a software design company that is totally not run by bees!

We are planning on developing some Kubernetes applications that could benefit from the cert-manager tool. We want to install this tool in the cluster. Luckily, there is a Helm chart we can use to make this easier.

First, install Helm in the cluster.

Then, install cert-manager using the bitnami/cert-manager chart located in the bitnami chart repository.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami
helm search repo cert-manager

k create ns cert-manager
helm install cert-manager bitnami/cert-manager -n cert-manager
helm list -n cert-manager
helm get notes cert-manager -n cert-manager
```
