## [CKAD Exercises](https://github.com/dgkanatsios/CKAD-exercises)

- Core Concepts
  - Get nginx pod's ip created in previous step, use a temp busybox image to wget its '/'
  - Create a pod that crashes, And get logs about the previous instance.
  - Create a busybox pod that echoes 'hello world' and then exits, pod should be deleted automatically when completed
- Multi-container pods
  - Create a pod with an nginx container exposed on port 80. Add a busybox init container which downloads a page using "wget -O /work-dir/index.html http://neverssl.com/online". Make a volume of type emptyDir and mount it in both containers. For the nginx container, mount it on "/usr/share/nginx/html" and for the initcontainer, mount it on "/work-dir". When done, get the IP of the created pod and create a busybox pod and run "wget -O- IP"
- Pod design
  - Check the annotations for pod nginx1
  - Create a pod that will be deployed to a Node that has the label 'accelerator=nvidia-tesla-p100'
  - Create a pod that will be placed on node controlplane. Use nodeSelector and tolerations.
    - in Minikube, taint minikube node with `node-role.kubernetes.io/control-plane` (eg k taint no minikube node-role.kubernetes.io/control-plane=true:NoSchedule)
  - Check the details of the fourth revision (number 4)
  - Autoscale the deployment, pods between 5 and 10, targetting CPU utilization at 80%
  - Implement canary deployment by running two instances of nginx marked as version=v1 and version=v2 so that the load is balanced at 75%-25% ratio
  - Create a job with the image busybox that executes the command 'echo hello;sleep 5;echo world'
    - make it terminate after 10 seconds
    - make it working to complete 5 times
    - make it working to complete 5 times in parallel
- Configuration
  - Create ResourceQuota in namespace one with hard requests cpu=1, memory=1Gi and hard limits cpu=2, memory=2Gi
  - Create a Secret named 'my-secret' of type 'kubernetes.io/ssh-auth' in the namespace 'secret-ops'. Define a single key named 'ssh-privatekey', and point it to the file 'id_rsa' in this directory.
  - Create a Pod named 'consumer' with the image 'nginx' in the namespace 'secret-ops', and consume the Secret as Volume. Mount the Secret as Volume to the path /var/app with read-only access. Open an interactive shell to the Pod, and render the contents of the file.
  - Generate an API token for the service account 'myuser'
- Observability
- Services and networking
  - Create an nginx deployment of 2 replicas, expose it via a ClusterIP service on port 80. Create a NetworkPolicy so that only pods with labels 'access: granted' can access the deployment and apply it
    - **don't have to create default deny all policy**
- State persistence
- helm
- Custom Resource Definitions

## KodeKloud

### 1

1. In the ckad-pod-design namespace, create a pod named privileged-pod that runs the nginx:1.17 image, and the container should be run in privileged mode.

- Is pod privileged-pod running?
- Is the container image is nginx:1.17?
- Is the container in privileged mode?

2. In the ckad-job namespace, create a job named very-long-pi that simply computes a π (pi) to 1024 places and prints it out.

This job should be configured to retry maximum 5 times before marking this job failed, and the duration of this job should not exceed 100 seconds.

- Use perl:5.34.0 image for your container.
- Is the job very-long-pi created?

3. In the ckad-multi-containers namespace, create pod named dos-containers-pod which has 2 containers matching the below requirements:

- The first container named alpha runs the nginx:1.17 image and has the ROLE=SERVER ENV variable configured.
- The second container named beta, runs busybox:1.28 image. This container will print message Hello multi-containers (command needs to be run in shell).

NOTE: all containers should be in a running state to pass the validation.

- Is the first pod's container running?
- Is the first container named alpha?
- Is the first container run nginx:1.17 image?
- Does the first container ENV configured correctly?
- Is the second pod's container running?
- Is the second container named beta?
- Does beta container run busybox:1.28 image?
- Does beta container run the required command?

4. In the ckad-multi-containers namespaces, create a ckad-sidecar-pod pod that matches the following requirements.

Pod has an emptyDir volume named my-vol.

The first container named main-container, runs nginx:1.16 image. This container mounts the my-vol volume at /usr/share/nginx/html path.

The second container named sidecar-container, runs busybox:1.28 image. This container mounts the my-vol volume at /var/log path.

Every 5 seconds, this container should write the current date along with greeting message Hi I am from Sidecar container to index.html in the my-vol volume.

- Is the main container running?
- Is the pod volume well configured?
- Is the correct message logged to main-container?

5. One application deployment called deluxe-apd got deployed on the wrong namespace. The team wants you to take the appropriate steps to deploy it on the dove-ns-8978f5ff7 namespace.

6. In the dev-apd namespace, one of the developers has performed a rolling update and upgraded the application to a newer version. But somehow, application pods are not being created.

To regain the working state, rollback the application to the previous version.

After rolling the deployment back, on the controlplane node, save the image currently in use to the /root/records/rolling-back-record.txt file and increase the replica count to 4.

You can SSH into the cluster1 using ssh cluster1-controlplane command.

- Is rolling back successful?
- Is the Image saved to a file?
- Is the deployment scaled?

7. Our new client wants to deploy the resources through the popular Helm tool. In the initial phase, our team lead wants to deploy nginx, a very powerful and versatile web server software that is widely used to serve static content, reverse proxying, load balancing, from the bitnami helm chart on the cluster3-controlplane node.

The chart URL and other specifications are as follows: -

1. The chart URL link - https://charts.bitnami.com/bitnami
2. The chart repository name should be polar.
3. The release name should be nginx-server.
4. All the resources should be deployed on the cd-tool-apd namespace.

NOTE: - You have to perform this task from the student-node.

- Is Helm repository created?
- Is Helm chart installed?
- Are resources deployed on ns?

helm repo add polar https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx
helm install nginx-server polar/nginx
heml list

8. We have deployed two applications called circle-apd and square-apd on the default namespace using the kodekloud/webapp-color:v1 and kodekloud/webapp-color:v2.

We have done all the tests and do not want circle-apd deployment to receive traffic from the foundary-svc service anymore. So, route all the traffic to another existing deployment.

Do change the service specifications to route traffic to the square-apd deployment.

You can test the application from the terminal by running the curl command with the following syntax: -

```
curl http://cluster3-controlplane:NODE-PORT

<!doctype html>
<title>Hello from Flask</title>
...
  <h2>
    Application Version: v2
  </h2>
```

As shown above, we will get the Application Version: v2 in the output.

- Is the application passed the test?
- Is the service updated?

9. Pod manifest file is already given under the /root/ directory called ckad-pod-aom.yaml.

There is error with manifest file correct the file and create resource.

- Pod is up and running
- Used correct apiVersion
- Image: busybox

10. Create a pod resou-limit using yaml file provided in the /root/resou-limit-aom.yaml .However, currently, there is an issue in the manifest. Find the issue, fix it and create the pod.

Do not change the values for the limits.

- Name: resou-limit-aom
- CPU request set to 1

11. Identify the kube api-resources that use api_version=storage.k8s.io/v1 using kubectl command line interface and store them in /root/api-version.txt on student-node.

- apiVersion: storage.k8s.io/v1
- Resources identified

12. Create a ConfigMap named ckad04-config-multi-env-files-aecs in the default namespace from the files provided at /root/ckad04-multi-cm directory.

- Is ConfigMap created with proper configuration ?

13. Update pod ckad06-cap-aecs in the namespace ckad05-securityctx-aecs to run as root user and with the SYS_TIME and NET_ADMIN capabilities.

Note: Make only the necessary changes. Do not modify the name of the pod.

- Are required capabilities added ?

14. We have a sample CRD at /root/ckad10-crd-aecs.yaml which should have the following validations:

- destinationName, country, and city must be string types.
- pricePerNight must be an integer between 50 and 5000.
- durationInDays must be an integer between 1 and 30.

Update the file incorporating the above validations in a namespaced scope.

Note: Remember to create the CRD after the required changes.

- Is the "Namespaced" scope configured ?
- Are correct keys of type "string" defined?
- Are correct keys of type "integer" defined?
- Is the correct range for key 'durationInDays' defined?
- Is the correct range for key 'pricePerNight' defined?

15. Create a role named pod-creater in the ckad20-auth-aecs namespace, and grant only the list, create and get permissions on pods resources.

Create a role binding named mock-user-binding in the same namespace, and assign the pod-creater role to a user named mock-user.

- Is correct resource for role "pod-creater" specified?
- Are correct "verbs" specified for the role?
- Is correct role used for rolebinding?
- Is correct user specified for rolebinding?

16. Using the pod template on student-node at /root/ckad08-dotfile-aecs.yaml , create a pod ckad08-top-secret-pod-aecs in the namespace ckad08-tp-srt-aecs with the specifications as defined below:

Define a volume section named secret-volume that is backed by a Kubernetes Secret named ckad08-dotfile-secret-aecs.

Mount the secret-volume volume to the container's /etc/secret-volume directory in read-only mode, so that the container can access the secrets stored in the ckad08-dotfile-secret-aecs secret.

- Is "read-only" volume created using "ckad08-dotfile-secret-aecs" ?
- Is 'readonly' volumeMount used with correct path ?

17. We have deployed an application named app-ckad-svcn in the default namespace. Configure a service multi-port-svcn for the application which exposes the pods at multiple ports with different protocols.

- Expose port 80 using the TCP with name http
- Expose port 53 using the UDP with name dns

==

- Is port 80 exposed using TCP?
- Is port 53 exposed using UDP?
- Is service multi-port-svcn created?
- Are correct labels used?

18. We have deployed a pod pod22-ckad-svcn in the default namespace. Create a service svc22-ckad-svcn that will expose the pod at port 6335.

Note: Use the imperative command for the above scenario.

- Is service svc22-ckad-svcn created?
- Is the pod exposed at port 6335?

19. A new payment service has been introduced. Since it is a sensitive application, it is deployed in its own namespace critical-space. Inspect the resources and service created.

You are requested to make the new application available at /pay. Create an ingress resource named ingress-ckad09-svcn for the payment application to make it available at /pay

Identify and implement the best approach to making this application available on the ingress controller and test to make sure its working. Look into annotations: rewrite-target as well.

- Is ingress ingress-ckad09-svcn created?
- Is ingress configured for service pay-service?
- Is the correct port configured?

20. Create an nginx pod called nginx-resolver-ckad03-svcn using image nginx, and expose it internally at port 80 with a service called nginx-resolver-service-ckad03-svcn.

- Is pod: nginx-resolver-ckad03-svcn created
- Is pod "nginx-resolver-ckad03-svcn" is exposed using "nginx-resolver-service-ckad03-svcn" ?

<!-- ##### -->

We have deployed some pods in the namespaces ckad-alpha and ckad-beta.

You need to create a NetworkPolicy named ns-netpol-ckad that will restrict all Pods in Namespace ckad-alpha to only have outgoing traffic to Pods in Namespace ckad-beta . Ingress traffic should not be affected.

However, the NetworkPolicy you create should allow egress traffic on port 53 TCP and UDP.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ns-netpol-ckad
  namespace: ckad-alpha
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - ports:
        - port: 53
          protocol: TCP
        - port: 53
          protocol: UDP
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ckad-beta
```

```bash
Name:         ns-netpol-ckad1
Namespace:    ckad-alpha
Created on:   2023-09-30 13:59:26 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Not affecting ingress traffic
  Allowing egress traffic:
    To Port: 53/TCP
    To Port: 53/UDP
    To:
      NamespaceSelector: kubernetes.io/metadata.name=ckad-beta
  Policy Types: Egress

```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ns-netpol-ckad1
  namespace: ckad-alpha
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ckad-beta
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
```

```bash
Name:         ns-netpol-ckad
Namespace:    ckad-alpha
Created on:   2023-09-30 13:56:39 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Not affecting ingress traffic
  Allowing egress traffic:
    To Port: 53/TCP
    To Port: 53/UDP
    To: <any> (traffic not restricted by destination)
    ----------
    To Port: <any> (traffic allowed to all ports)
    To:
      NamespaceSelector: kubernetes.io/metadata.name=ckad-beta
  Policy Types: Egress
```
