## Mock Exam - 1

Update pod app-sec-kff3345 to run as Root user and with the SYS_TIME capability.

- Pod Name: app-sec-kff3345
- Image Name: ubuntu
- SecurityContext: Capability SYS_TIME

```bash
    securityContext:
      runAsUser: 0
      capabilities:
        add: ["SYS_TIME"]
```

Create a redis deployment using the image redis:alpine with 1 replica and label app=redis. Expose it via a ClusterIP service called redis on port 6379. Create a new Ingress Type NetworkPolicy called redis-access which allows only the pods with label access=redis to access the deployment.

Image: redis:alpine
Deployment created correctly?
Service created correctly?
Network Policy allows the correct pods?
Network Policy applied on the correct pods?

```bash
k create deploy redis --image=redis:alpine
k expose deploy redis --port=6379

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: redis-access
spec:
  podSelector:
    matchLabels:
      app: redis
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              access: redis
```

Create a Pod called sega with two containers:

1. Container 1: Name tails with image busybox and command: sleep 3600.
2. Container 2: Name sonic with image nginx and Environment variable: NGINX_PORT with the value 8080.

Container Sonic has the correct ENV name
Container Sonic has the correct ENV value
Container tails created correctly?

```bash
k run sega --image=busybox --dry-run=client -o yaml -- sleep 3600 > sega.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: sega
  name: sega
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox
    name: tails
    resources: {}
  - image: nginx
    name: sonic
    env:
    - name: NGINX_PORT
      value: "8080"
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

## Mock Exam - 1

Create a deployment called my-webapp with image: nginx, label tier:frontend and 2 replicas. Expose the deployment as a NodePort service with name front-end-service , port: 80 and NodePort: 30083

Deployment my-webapp created?

image: nginx

Replicas = 2 ?

service front-end-service created?

service Type created correctly?

Correct node Port used?

```bash
k create deploy my-webapp --image=nginx --replicas=2 --dry-run=client -o yaml > deploy.yaml

k expose deploy my-webapp --name front-end-service --port=80 --type=NodePort --dry-run=client -o yaml > svc.yaml
```

Add a taint to the node node01 of the cluster. Use the specification below:

key: app_type, value: alpha and effect: NoSchedule
Create a pod called alpha, image: redis with toleration to node01.

node01 with the correct taint?
Pod alpha has the correct toleration?

```bash
kubectl taint nodes node01 app_type=alpha:NoSchedule

k run alpha --image=redis --dry-run=client -o yaml > alpha.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: alpha
  name: alpha
spec:
  containers:
  - image: redis
    name: alpha
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
  - key: "app_type"
    operator: "Equal"
    value: "alpha"
    effect: "NoSchedule"
```

Apply a label app_type=beta to node controlplane. Create a new deployment called beta-apps with image: nginx and replicas: 3. Set Node Affinity to the deployment to place the PODs on controlplane only.

NodeAffinity: requiredDuringSchedulingIgnoredDuringExecution

controlplane has the correct labels?

Deployment beta-apps: NodeAffinity set to requiredDuringSchedulingIgnoredDuringExecution ?

Deployment beta-apps has correct Key for NodeAffinity?

Deployment beta-apps has correct Value for NodeAffinity?

Deployment beta-apps has pods running only on controlplane?

Deployment beta-apps has 3 pods running?

```bash
k label node controlplane app_type=beta

k create deploy beta-apps --image=nginx --replicas=3 --dry-run=client -o yaml > beta-apps.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: beta-apps
  name: beta-apps
spec:
  replicas: 3
  selector:
    matchLabels:
      app: beta-apps
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: beta-apps
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: app_type
                operator: In
                values:
                - beta
```

Create a new Ingress Resource for the service my-video-service to be made available at the URL: http://ckad-mock-exam-solution.com:30093/video.

To create an ingress resource, the following details are: -

annotation: nginx.ingress.kubernetes.io/rewrite-target: /

host: ckad-mock-exam-solution.com

path: /video

Once set up, the curl test of the URL from the nodes should be successful: HTTP 200

http://ckad-mock-exam-solution.com:30093/video accessible?

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: "ckad-mock-exam-solution.com"
    http:
      paths:
      - pathType: Prefix
        path: "/video"
        backend:
          service:
            name: my-video-service
            port:
              number: 8080
```

We have deployed a new pod called pod-with-rprobe. This Pod has an initial delay before it is Ready. Update the newly created pod pod-with-rprobe with a readinessProbe using the given spec

httpGet path: /ready

httpGet port: 8080

readinessProbe with the correct httpGet path?

readinessProbe with the correct httpGet port?

```bash

```

Create a new pod called nginx1401 in the default namespace with the image nginx. Add a livenessProbe to the container to restart it if the command ls /var/www/html/probe fails. This check should start after a delay of 10 seconds and run every 60 seconds.

You may delete and recreate the object. Ignore the warnings from the probe.

Pod created correctly with the livenessProbe?

```bash
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx1401
  name: nginx1401
spec:
  containers:
  - image: nginx
    name: nginx1401
    resources: {}
    livenessProbe:
      exec:
        command:
        - ls
        - /var/www/html/probe
      initialDelaySeconds: 10
      periodSeconds: 60
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

Create a job called whalesay with image docker/whalesay and command "cowsay I am going to ace CKAD!".

completions: 10

backoffLimit: 6

restartPolicy: Never

This simple job runs the popular cowsay game that was modifed by docker…

Job "whalesay" uses correct image?

Job "whalesay" configured with completions = 10?

Job "whalesay" with backoffLimit = 6

Job run's the command "cowsay I am going to ace CKAD!"?

Job "whalesay" completed successfully?

```bash
k create job whalesay --image=docker/whalesay --dry-run=client -o yaml -- sh -c "cowsay I am going to ace CKAD!" > job.yaml

apiVersion: batch/v1
kind: Job
metadata:
  name: whalesay
spec:
  completions: 10
  backoffLimit: 6
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - command:
        - sh
        - -c
        - "cowsay I am going to ace CKAD!"
        image: docker/whalesay
        name: whalesay
      restartPolicy: Never
```
