## Exam 1

```bash
kubectl config use-context acgk8s

/home/cloud_user/verify.sh
```

1. Fix a Deployment with an Incorrect Image Name

A Deployment in the default Namespace is not working correctly due to a misspelled image name. Identify which Deployment is broken, and fix the issue.

**2. Fix an Issue with a Broken Pod**

The bat Deployment in the cave Namespace is having some issues. Check the log for one of this Deployment's Pods to determine what is wrong. Then, modify the Deployment to fix the issue.

Note: You do not need to make changes to any object other than the Deployment, although you may need to view other objects as you investigate how to solve the problem.

## Exam 2

1. Configure a Deployment's Pods to Use an Existing ServiceAccount

There is a Deployment called han in the default Namespace. Modify this Deployment so that its Pods use the falcon-sa ServiceAccount.

2. Customize Security Settings for a Deployment's Pods

Find a Deployment called lando in the default Namespace. For this Deployment's containers, allow privilege escalation, and configure the container process to run as the user with user ID 2727.

## Exam 3

1. Create a ConfigMap

Create a ConfigMap called kenobi in the yoda Namespace.

Store the following configuration data in the ConfigMap:

planet: hoth

2. Create a Pod That Consumes the ConfigMap as a Mounted Volume

Create a Pod called chewie in the yoda Namespace. Use the nginx:stable image.

Provide the kenobi ConfigMap data to this Pod as a mounted volume at the path /etc/starwars.

The volume name must be defined as kenobi-cm.

## Exam 4

1. Change the Rollout Settings for an Existing Deployment

There is a Deployment called fish in the default Namespace.

Change the maxUnavailable for this Deployment to 2. Change maxSurge to 50%.

2. Perform a Rolling Update

Perform a rolling update to change the image used in the fish Deployment to nginx:1.21.5.

3. Roll Back a Deployment to the Previous Version

Roll back the fish Deployment to the previous version.

## Exam 5

1. Create a PersistentVolume

Create a PersistentVolume called pv-data in the default Namespace.

Set the storage amount to 1Gi and the storage class to static.

Use a hostPath to mount the host directory /var/pvdata with the PersistentVolume.

2. Create a Pod That Consumes Storage from the PersistentVolume

Create a Pod called pv-pod in the default Namespace.

Use the busybox:stable image with the command sh -c while true; do sleep 3600; done.

Use the PersistentVolume to provide storage to this Pod's container at the path /var/data.

If everything is set up correctly, you should be able to find some data exposed to the container by the PersistentVolume at /var/data/data.txt.

## Exam 6

1. Create a Pod with Resource Requests

Create a Pod in the dev Namespace called apple. Use the nginx:stable image.

Configure this Pod's container with resource requests for 256Mi memory and 250m CPU.

2. Create and Consume a Secret

In the secure Namespace, create a Secret called secret-code.

You can get a a base64-encoded string for the Secret data via:

`echo trustno1 | base64`

Add the following key-value data to the Secret:

```
  code: [insert the base64-encoded string here]
```

In the same Namespace, create a Pod called secret-keeper. Use the busybox:stable image. Configure the container to run the command `sh -c echo $SECRET_STUFF; sleep 3600`.

Provide the Secret's code key to the container as an environment variable called SECRET_STUFF. If done correctly, the container's log should show the Secret data, trustno1.

## Exam 7

**1. Run a Job on a Schedule**

In the one Namespace, run a Job that executes repeatedly on a schedule. Use a CronJob called pwd-runner to do this.

The Job should run the pwd command once every minute. Use the busybox:stable image. If the command takes longer than 10 seconds to execute, it should be automatically terminated.

Verify that the Job runs successfully at least once.

2. Create a Deployment

Create a Deployment called nginx-dep in the two Namespace.

Use the nginx:stable image, and run with 3 replicas. Expose port 8081, and add an environment variable to the containers called NGINX_PORT with the value 8081. This will cause the nginx container to listen on port 8081.

## Exam 8

**1. Locate and Fix a Failing Liveness Probe**

Somewhere in the cluster, there is a Pod that is broken due to a failing liveness probe.

Locate this Pod and record the Namespace and Pod name in the file /home/cloud_user/probe-fix/broken-pod-name.txt. Store the data in the form namespace/podname.

Next, get a list of events for the Pod's Namespace using kubectl get events. Use the wide output format to retrieve additional information. Store the output of this command in the file /home/cloud_user/probe-fix/events.txt.

Finally, fix the underlying issue with the liveness probe to get the Pod running.

2. Find the Pod with the Highest CPU Usage

Locate the Pod within the cpu Namespace that is using the most CPU resources.

Save the name of that Pod in the file /home/cloud_user/metrics/high-cpu-pod-name.txt.

## Exam 9

1. Expose an Application with a NodePort Service

There is a Deployment called willow in the buffy Namespace.

Expose this Deployment on port 8082 and target port 80 using a NodePort-type Service called willow-svc.

2. Provide Network Access between Pods via a NetworkPolicy

There are several Pods in the giles Namespace. The xander Pod needs to be able to reach out to both api-1 and api-2, but it currently cannot do so due to the NetworkPolicy setup.

Without creating, changing, or removing any existing NetworkPolicies, provide the xander Pod with access to api-1 and api-2, but not any other Pods in the Namespace. You should be able to do this by only making changes to the xander Pod and no other objects.

## Exam 10

1. Create a Blue/Green Setup for an Existing Deployment

Create a blue/green Deployment setup for the existing web-frontend Deployment in the bluegreen Namespace.

You can find a Deployment manifest for web-frontend on the CLI server at /home/cloud_user/bluegreen/web-frontend.yml. Feel free to copy this manifest in order to create your green Deployment.

Give the green Deployment the name web-frontend-green and set the env label to green in the Pod template.

Once you have created the green Deployment and verified that it is working, modify the web-frontend-svc Service so that it points only to the new green Deployment's Pods. This is a NodePort Service, and you can test it by reaching out to port 30081 on any of the cluster nodes, for example: curl k8s-control:30081.

2. Create a Canary Setup for an Existing Deployment

Create a canary Deployment setup for the existing auth Deployment in the canary Namespace.

There is a manifest file for the existing Deployment at /home/cloud_user/canary/auth.yml. You can copy this file to create your canary Deployment.

Give the canary Deployment the name auth-canary, and set the env label in the Pod template to canary.

There is a Service called auth-svc, also in the canary Namespace. Modify this Service to direct traffic to both the main and canary Deployments. Configure your setup so that there will be 4 total replicas, including both the main Deployment and the canary Deployment, and so that approximately 25% of traffic will go to the canary Pod(s). Note that you may need to modify the original main Deployment in order to accomplish this.

The Service is a NodePort Service, and you can test it by reaching out to port 30082 on any of the cluster nodes, for example: curl k8s-control:30082.

## Exam 11

1. Create a ConfigMap to Store an `haproxy` Config File

Create a ConfigMap called haproxy-config in the default Namespace to store the haproxy configuration for an haproxy ambassador container.

In the ConfigMap, store the following config file in a key called haproxy.cfg:

```
frontend ambassador
  bind *:7171
  default_backend api_svc
backend api_svc
  server svc api-svc:8181
```

2. Update a Service to Serve on a New Port.

In the default Namespace, there is a Service called api-svc. This Service serves an API that is accessed by the client Pod.

Change the Service's exposed port to 8181. This will temporarily break the client Pod's communication with the Service since the client Pod is still using the old port.

3. Re-configure a Pod to use an haproxy ambassador container.

In the default Namespace, there is a Pod called client. This Pod should be unable to reach the api-svc Service since the Service's port was changed. Fix this issue by adding an ambassador container to the client Pod that uses haproxy to forward traffic to the Service's new port.

You can find manifest file for this Pod at /home/cloud_user/client.yml. Note that you may need to delete and re-create the Pod in order to make certain changes.

First, modify the command of the client Pod's main container so that it reaches out to localhost instead of api-svc. Do not change the port number that is used within this command.

Add an haproxy ambassador container to the client Pod using the haproxy:2.4 image. Mount the haproxy-config ConfigMap to the ambassador container at /usr/local/etc/haproxy/. This will cause the ConfigMap's haproxy configuration data to configure haproxy in the ambassador container.

Once this is done, the client Pod's main container should be able to contact the api-svc successfully again. You can check the container's logs with kubectl logs client -c main.

## Exam 12

1. Create a Dockerfile

Create a Dockerfile for an application.

There is a project directory at /home/cloud_user/buzz. All the necessary files are in this directory. Create a Dockerfile in /home/cloud_user/buzz.

Use the busybox:1.34.1 image as the baseline for your new image.

Configure the Dockerfile to place data1.txt from the buzz directory into the resulting container image at /etc/data/mainData.txt.

Add data2.txt to the container image at /etc/data/data2.txt, and add data3.txt to the container image at /etc/data/data3.txt.

2. Build and Save a Container Image

Build a container image using your Dockerfile located at /home/cloud_user/buzz/Dockerfile. Docker is already installed on the CLI server, and you can use Docker to build the image.

Give this image the tag buzz:1. You do not need to run a container using this image or push it to any remote repository.

Save a copy of the image to an archive file located at /home/cloud_user/buzz_1.tar.
