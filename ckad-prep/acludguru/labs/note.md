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

## 5. Implementing Health Checks in a Kubernetes Application

Welcome to HiveCorp, a software design company that is totally not run by bees!

We have recently deployed a new set of tools to our Kubernetes cluster, but there are some problems that need to be resolved.

One component called comb-dashboard is an application that serves HTTP requests. A bug in the code is causing it to randomly begin responding with error status codes, but the container process continues to run. Currently, the only way to fix the issue when it arises is to restart the application. Implement a probe that will cause the container to be automatically restarted when it begins responding with errors.

Another component, comb-monitor, is entering the ready status too early, before it has a chance to fully start up. Create a probe that will detect when the container is fully started up by running a test command.

1. Add a Liveness Probe

The comb-dashboard Deployment can be found in the hive Namespace.

Edit the Deployment so that the containers are automatically restarted whenever they begin responding to HTTP requests with an error status code.

The container application listens on port 80, and you can use the root path / to test whether the bug is occurring.

2. Add a Readiness Probe

You can find the comb-monitor in the hive Namespace.

Edit this Deployment and add a probe that will verify that the application can execute command-line commands before the container is considered ready.

You can use a simple command like echo This is a test!.

## 6. Debugging a Kubernetes Application

Welcome to HiveCorp, a software design company that is totally not run by bees!

We are working on building some applications in our Kubernetes cluster, but there are some issues. We need you identify what is wrong and fix these problems!

First, some Deployment's Pods are unable to start up (they won't even enter the Running status). Unfortunately, whoever reported this issue didn't provide much information, so you will need to locate this issue and fix it.

Second, a Deployment called users-rest has Pods that are running, but they are not receiving any user traffic. Investigate why this is happening and correct the issue.

```bash
k apply -f https://raw.githubusercontent.com/ACloudGuru-Resources/content-cka-resources/master/metrics-server-components.yaml
```

1. Fix a Broken Deployment

There is a Deployment in a cluster whose Pods are unable to enter the Running status. It is not simply the containers that are unready — the Pods themselves are not Running.

Identify this Deployment and correct the issue.

2. Fix an Application That Is Not Receiving User Traffic

The users-rest Deployment in the hive Namespace has Pods that are starting up (meaning that the Pods are in the Running status), but these Pods are not receiving user traffic.

Investigate to identify the problem and fix it.

```bash
# /var/run/secrets/kubenetes.io/serviceaccount/token
# /var/run/secrets/kubenetes.io/serviceaccount/ca.crt
curl -s --header "Authorization: Bearer $(cat /var/run/secrets/kubenetes.io/serviceaccount/token)" \
  --cacert /var/run/secrets/kubenetes.io/serviceaccount/ca.crt \
  https://kubernetes/api/v1/namespaces/default/pods
```

## 7. Managing Resource Usage in Kubernetes

Welcome to HiveCorp, a software design company that is totally not run by bees!

We have been expanding our usage of Kubernetes. However, as our applications have grown more complex, we have run into issues with the availability of compute resources. It is time to build a more sophisticated way of planning for and controlling resource usage in our cluster!

You will need to set up resource requests and limits for a Deployment in the cluster. Once that is done, set up a quota to limit the amount of resources that can be consumed in the hive Namespace.

1. Configure Resource Requests for a Deployment

There is a Deployment called royal-jelly in the hive Namespace.

Add resource requests to this Deployment's containers. The container should request 128Mi memory and 250m CPU.

2. Add resource limits to the Deployment called royal-jelly in the hive Namespace.

For the containers in this Deployment, the limits should be 256Mi for memory and 500m for CPU.

3. Use a quota to limit the resources that can be used in the hive Namespace.

The quota should allow total resource requests in the Namespace up to 1Gi for memory and 1 CPU.

For resource limits, the quota should allow up to 2Gi for memory and 2 CPU.

Note: The ResourceQuota admission controller is already enabled in the environment. You do not need to enable it.

## 8. Configuring Applications in Kubernetes

Welcome to HiveCorp, a software design company that is totally not run by bees!

We have an application that needs some external configuration. It has a daily message that needs to be configured as well as a secret key that will need to be stored more securely.

Create a ConfigMap and Secret to store the necessary configuration data. Then, modify a Deployment to pass the configuration data from the ConfigMap and Secret to the containers as requested.

1. Create a ConfigMap

Create a ConfigMap in the hive Namespace called honey-config.

Store the following data in the ConfigMap:

```
honey.cfg: |
  There is always money in the honey stand!
```

2. Create a Secret

Create a Secret called hive-sec in the hive Namespace.

Store the following value in the Secret:

hiveToken: secretToken!
Note that you will need to base64-encode the secretToken! value.

3. In the hive Namespace, there is a Deployment called hive-mgr. Edit this Deployment so that the container is able to access the data from the ConfigMap and Secret.

For the Secret, provide the value of the hiveToken key to the container as an environment variable called TOKEN.

For the ConfigMap, load the data from the honey.cfg key using a mounted volume. The data should ultimately be accessible by the container at the path /config/honey.cfg.

## 9. Welcome to HiveCorp, a software design company that is totally not run by bees!

We are working on setting up our external landing page, hive.io. The application Deployment is already set up, but we need to configure a Service and an Ingress to expose the application.

The Ingress controller is already set up. Create a Service to expose the existing Deployment. Then, create an Ingress that uses this Service as a backend.

1. Create a Service to Expose the Application

The application's Deployment is called hive-io-frontend and exists in the hive Namespace.

The application's web server listens on port 80. Create a Service called hive-io-frontend-svc to expose this application on port 8080. The Service only needs to expose the application within the cluster network.

2. Expose the Application Externally Using an Ingress

Create an Ingress to expose the application.

An Ingress controller is already installed. You can use nginx for the ingressClassName.

Configure the application using hive.io for the domain. The lab server already has an entry in /etc/hosts set up for this domain, so you do not need to make any changes to /etc/hosts.

Remember that the application's Service listens on port 8080.

```
k expose deploy hive-io-frontend --name=hive-io-frontend-svc --port=8080 --target-port=80 -n hive --dry-run=client -o yaml
```
