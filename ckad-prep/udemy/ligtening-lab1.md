1. Create a Persistent Volume called log-volume. It should make use of a storage class name manual. It should use RWX as the access mode and have a size of 1Gi. The volume should use the hostPath /opt/volume/nginx

Next, create a PVC called log-claim requesting a minimum of 200Mi of storage. This PVC should bind to log-volume.

Mount this in a pod called logger at the location /var/www/nginx. This pod should use the image nginx:alpine.

```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: log-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/opt/volume/nginx"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: log-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 200Mi

apiVersion: v1
kind: Pod
metadata:
  name: logger
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: log-claim
  containers:
    - name: task-pv-container
      image: nginx:alpine
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/var/www/nginx"
          name: task-pv-storage
```

2. We have deployed a new pod called secure-pod and a service called secure-service. Incoming or Outgoing connections to this pod are not working.
   Troubleshoot why this is happening.

Make sure that incoming connection from the pod webapp-color are successful.

Important: Don't delete any current objects deployed.
Important: Don't Alter Existing Objects!
Connectivity working?

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  creationTimestamp: "2023-09-18T02:32:37Z"
  generation: 1
  name: default-deny
  namespace: default
  resourceVersion: "4620"
  uid: ce82a1b2-387a-4000-9658-4bcd4030bc7d
spec:
  podSelector:
    matchLabels:
      name: webapp-color
  policyTypes:
  - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              run: secure-pod
      ports:
        - protocol: TCP
          port: 80
status: {}
```

3. Create a pod called time-check in the dvl1987 namespace. This pod should run a container called time-check that uses the busybox image.

1) Create a config map called time-config with the data TIME_FREQ=10 in the same namespace.
2) The time-check container should run the command: while true; do date; sleep $TIME_FREQ;done and write the result to the location /opt/time/time-check.log.
3) The path /opt/time on the pod should mount a volume that lasts the lifetime of this pod.

Pod time-check configured correctly?

```bash
k create ns dvl1987

k config set-context --current --namespace=dvl1987
k run time-check --image=busybox --dry-run=client -o yaml -- /bin/sh -c "while true; do date; sleep $TIME_FREQ; done" > time-check.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: time-check
  name: time-check
spec:
  volumes:
  - name: logger
    emptyDir: {}
  containers:
  - args:
    - /bin/sh
    - -c
    - while true; do date > /opt/time/time-check.log; sleep $TIME_FREQ; done;
    image: busybox
    name: time-check
    env:
      - name: TIME_FREQ
        valueFrom:
          configMapKeyRef:
            name: time-config
            key: TIME_FREQ
    volumeMounts:
    - mountPath: /opt/time
      name: logger
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

4. Create a new deployment called nginx-deploy, with one single container called nginx, image nginx:1.16 and 4 replicas.
   The deployment should use RollingUpdate strategy with maxSurge=1, and maxUnavailable=2.

Next upgrade the deployment to version 1.17.

Finally, once all pods are updated, undo the update and go back to the previous version.

Deployment created correctly?
Was the deployment created with nginx:1.16?
Was it upgraded to 1.17?
Deployment rolled back to 1.16?

```bash
k create deploy nginx-deploy --image=nginx:1.16 --replicas=4 --dry-run=client -o yaml > nginx-d.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx-deploy
  name: nginx-deploy
spec:
  replicas: 4
  selector:
    matchLabels:
      app: nginx-deploy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2
      maxSurge: 1
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx-deploy
    spec:
      containers:
      - image: nginx:1.16
        name: nginx
        resources: {}

k set image deploy nginx-deploy nginx=nginx:1.17
```

5. Create a redis deployment with the following parameters:

Name of the deployment should be redis using the redis:alpine image. It should have exactly 1 replica.

The container should request for .2 CPU. It should use the label app=redis.

It should mount exactly 2 volumes.

a. An Empty directory volume called data at path /redis-master-data.
b. A configmap volume called redis-config at path /redis-master.
c. The container should expose the port 6379.

The configmap has already been created.

Deployment created correctly?

```bash
apiVersion: v1
data:
  redis-config: |
    maxmemory 2mb
    maxmemory-policy allkeys-lru
kind: ConfigMap
metadata:
  name: redis-config

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: redis
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: redis
    spec:
      volumes:
      - name: data
        emptyDir: {}
      - name: redis-config
        configMap:
          name: redis-config
      containers:
      - image: redis:alpine
        name: redis
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: data
          mountPath: "/redis-master-data"
        - name: redis-config
          mountPath: "/redis-master"
        resources:
          requests:
            cpu: "0.2"
```
