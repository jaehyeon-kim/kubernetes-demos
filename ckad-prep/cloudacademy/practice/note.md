## Prep

- https://kubernetes.io/docs
- https://helm.sh/docs

## CKAD Practice Exam

### Core Concepts

1. Create a Pod in the cre Namespace with the following configuration:

The Pod is named basic
The Pod uses the nginx:stable-alpine-perl image for its only container
Restart the Pod only OnFailure
Ensure port 80 is open to TCP traffic

```bash
k run basic --image=nginx:stable-alpine-perl --restart=OnFailure --port=80 -n cre
```

2. Check 2: Create a Namespace and Launch a Pod within it with Labels
   Create a new Namespace named workers and within it launch a Pod with the following configuration:

The Pod is named worker
The Pod uses the busybox image for its only container
Restart the Pod Never
Command: /bin/sh -c "echo working... && sleep 3600"
Label 1: company=acme
Label 2: speed=fast
Label 3: type=async

```bash
k create ns workers
k run worker --image=busybox --restart=Never --labels="company=acme,speed=fast,type=async" -n workers -- /bin/sh -c "echo working... && sleep 3600"
```

3. Check 3: Update the Label on a Running Pod
   The ca200 namespace contains a running Pod named compiler. Without restarting the pod, update and change it's language label from java to python.

```bash
kubectl label po compiler language=python --overwrite -n ca200
```

4. Check 4: Get the Pod IP Address using JSONPath
   Discover the Pod IP address assigned to the pod named ip-podzoid running in the ca300 namespace using JSONPath (hint: use -o jsonpath). Once you've established the correct kubectl command to do this, save the command (not the result) into a file located here: /home/ubuntu/podip.sh

```bash
echo "k get po ip-podzoid -n ca300 -o jsonpath='{.status.podIP}'" > /home/ubuntu/podip.sh
```

5. Check 5: Generate Pod YAML Manifest File
   Generate a new Pod manifest file which contains the following configuration:

(Make sure to use the exact values below or the checks will fail.)

Pod name: borg1
Namespace to launch in: core-system
Container image: busybox
Command: /bin/sh -c "echo borg.running... && sleep 3600"
Restart policy: Always
Pod label: platform=prod
Environment variable: system=borg
Save the resulting manifest to the following location: /home/ubuntu/pod.yaml

```bash
k run borg1 --image=busybox --restart=Always --labels="platform=prod" --env="system=borg" -n=core-system --dry-run=client -o yaml -- /bin/sh -c 'echo borg.running... && sleep 3600' > /home/ubuntu/pod.yaml
```

6. Check 6: Launch Pod and Configure it's Termination Shutdown Time
   Launch a new web server Pod in the sys2 namespace with the following configuration:

Pod name: web-zeroshutdown
Container image: nginx
Restart policy: Never
Ensure the pod is configured to terminate immediately when requested to do so by configuring it's terminationGracePeriodSeconds setting.

```bash
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: web-zeroshutdown
  name: web-zeroshutdown
  namespace: sys2
spec:
  containers:
  - image: nginx
    name: web-zeroshutdown
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Never
  terminationGracePeriodSeconds: 0
```

### Configuration

Check 1: Create and Consume a Secret using a Volume
Create a secret named app-secret in the yqe Namespace that stores key-value pair of password=abnaoieb2073xsj

Create a Pod that consumes the app-secret Secret using a Volume that mounts the Secret in the /etc/app directory. The Pod should be named app and run a memcached container.

```bash
k create secret generic app-secret --from-literal=password=abnaoieb2073xsj -n yqe

apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: yqe
spec:
  volumes:
    - name: app-secret-volume
      secret:
        secretName: app-secret
  containers:
    - name: app-container
      image: memcached
      volumeMounts:
        - name: app-secret-volume
          mountPath: "/etc/app"
```

Check 2: Update Deployment with New Service Account
A Deployment named secapp has been created in the app namespace and currently uses the default ServiceAccount. Create a new ServiceAccount named secure-svc in the app namespace and then use it within the existing secapp Deployment, ensuring that the replicas now run with it.

```bash
k create sa secure-svc -n app

k edit deploy secapp -n app
## pod spec
serviceAccountName: secure-svc

## using patch
# Create a file named patch.yaml and configure the replicas serviceAccountName to be secure-svc
spec:
  template:
    spec:
      serviceAccountName: secure-svc
# Patch the existing Deployment
kubectl patch deployment -n app secapp --patch "$(cat patch.yaml)"
```

Check 3: Pod Security Context Configuration
Create a pod named secpod in the dnn namespace which includes 2 containers named c1 and c2. Both containers must be configured to run the bash image, and should execute the command /usr/local/bin/bash -c sleep 3600. Container c1 should run as user ID 1000, and container c2 should run as user ID 2000. Both containers should use file system group ID 3000.

```bash
k run c1 --image=bash -n dnn --dry-run=client -o yaml -- /usr/local/bin/bash -c sleep 3600 > secpod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: secpod
  namespace: dnn
spec:
  securityContext:
    fsGroup: 3000
  containers:
  - args:
    - /usr/local/bin/bash
    - -c
    - "sleep 3600"
    image: bash
    name: c1
    securityContext:
      runAsUser: 1000
  - args:
    - /usr/local/bin/bash
    - -c
    - "sleep 3600"
    image: bash
    name: c2
    securityContext:
      runAsUser: 2000
```

Check 4: Pod Resource Constraints
Create a new Pod named web1 in the ca100 namespace using the nginx image. Ensure that it has the following 2 labels env=prod and type=processor. Configure it with a memory request of 100Mi and a memory limit at 200Mi. Expose the pod on port 80.

```bash
k run web1 --image=nginx --labels="env=prod,type=processor" --port 80 -n ca100 --dry-run=client -o yaml > web1.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    env: prod
    type: processor
  name: web1
  namespace: ca100
spec:
  containers:
  - image: nginx
    name: web1
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: 100Mi
      limits:
        memory: 200Mi
```

Check 5: Create a Pod with Config Map Environment Vars
Create a new ConfigMap named config1 in the ca200 namespace. The new ConfigMap should be created with the following 2 key/value pairs:

COLOUR=red
SPEED=fast
Launch a new Pod named redfastcar in the same ca200 namespace, using the image busybox. The redfastcar pod should expose the previous ConfigMap settings as environment variables inside the container. Configure the redfastcar pod to run the command: /bin/sh -c "env | grep -E 'COLOUR|SPEED'; sleep 3600"

```bash
k create cm config1 --from-literal=COLOUR=red --from-literal=SPEED=fast -n ca200

k run redfastcar --image=busybox -n ca200 --dry-run=client -o yaml -- /bin/sh -c "env | grep -E 'COLOUR|SPEED'; sleep 3600" > redfastcar.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: redfastcar
  name: redfastcar
  namespace: ca200
spec:
  containers:
  - args:
    - /bin/sh
    - -c
    - env | grep -E 'COLOUR|SPEED'; sleep 3600
    image: busybox
    name: redfastcar
    resources: {}
    env:
    - name: COLOUR
      valueFrom:
        configMapKeyRef:
          name: config1
          key: COLOUR
    - name: SPEED
      valueFrom:
        configMapKeyRef:
          name: config1
          key: SPEED
```

### Multi-Container Pods

Check 1: Pod with Legacy Logs
A Pod in the mcp namespace has a single container named random that writes its logs to the /var/log/random.log file. Add a second container named second that uses the busybox image to allow the following command to display the logs written to the random container's /var/log/random.log file:

kubectl -n mcp logs random second

```bash
## Before
apiVersion: v1
kind: Pod
metadata:
  name: random
spec:
  containers:
  - args:
    - /bin/sh
    - -c
    - while true; do shuf -i 0-1 -n 1 >> /tmp/random.log; sleep 1; done
    image: busybox
    name: random

## After
apiVersion: v1
kind: Pod
metadata:
  name: random
spec:
  volumes:
  - name: sidecar
    emptyDir: {}
  containers:
  - args:
    - /bin/sh
    - -c
    - while true; do shuf -i 0-1 -n 1 >> /tmp/random.log; sleep 1; done
    image: busybox
    name: random
    volumeMounts:
    - name: sidecar
      mountPath: /tmp
  - args:
    - /bin/sh
    - -c
    - while true; do tail -n+1 /tmp/random.log; done
    image: busybox
    name: second
    volumeMounts:
    - name: sidecar
      mountPath: /tmp
```

Check 2: Multi Container Pod Networking
The following multi-container Pod manifest needs to be updated BEFORE being deployed. Container c2 is designed to make HTTP requests to container c1. Before deploying this manifest, update it by substituting the <REPLACE_HOST_HERE> placeholder with the correct host or IP address - the remaining parts of the manifest must remain unchanged. Once deployed - confirm that the solution works correctly by executing the command kubectl logs -n app1 webpod -c c2 > /home/ubuntu/webpod-log.txt. The resulting /home/ubuntu/webpod-log.txt file should contain a single string within it.

Multi-Container Pod Manifest:

apiVersion: v1
kind: Pod
metadata:
name: webpod
namespace: app1
spec:
restartPolicy: Never
volumes:

- name: vol1
  emptyDir: {}
  containers:
- name: c1
  image: nginx
  volumeMounts:
  - name: vol1
    mountPath: /usr/share/nginx/html
    lifecycle:
    postStart:
    exec:
    command: - "bash" - "-c" - |
    date | sha256sum | tr -d " \*-" > /usr/share/nginx/html/index.html
- name: c2
  image: appropriate/curl
  command: ["/bin/sh", "-c", "curl -s http://<REPLACE_HOST_HERE> && sleep 3600"]

```bash

```

Check 3: Add New Container with ReadOnly Volume
Update and deploy the provided /home/ubuntu/md5er-app.yaml manifest file, adding a second container named c2 to the existing md5er Pod. The c2 container will run the same bash image that the c1 container already uses. The c2 container must mount the existing vol1 volume in read only mode, and such that it can execute the following bash script:

for word in $(</data/file.txt)
do
echo $word | md5sum | awk '{print $1}'
done
Note: The above command will simply generate an MD5 hash for each individual word found within the /data/file.txt file (generated by the c1 container).

Once deployed, run the following command to save the stdout output of the c2 container:

kubectl logs -n app2 md5er c2 > /home/ubuntu/md5er-output.log

```bash
k create cm cm1 --from-literal=data=bla

## Before
apiVersion: v1
kind: Pod
metadata:
 name: md5er
spec:
 restartPolicy: Never
 volumes:
 - name: vol1
   emptyDir: {}
 containers:
 - name: c1
   image: bash
   env:
   - name: DATA
     valueFrom:
      configMapKeyRef:
       name: cm1
       key: data
   volumeMounts:
   - name: vol1
     mountPath: /data
   command: ["/usr/local/bin/bash", "-c", "echo $DATA > /data/file.txt"]

## After
apiVersion: v1
kind: Pod
metadata:
 name: md5er
spec:
 restartPolicy: Never
 volumes:
 - name: vol1
   emptyDir: {}
 containers:
 - name: c1
   image: bash
   env:
   - name: DATA
     valueFrom:
      configMapKeyRef:
       name: cm1
       key: data
   volumeMounts:
   - name: vol1
     mountPath: /data
   command: ["/usr/local/bin/bash", "-c", "echo $DATA > /data/file.txt"]
 - name: c2
   image: bash
   volumeMounts:
   - name: vol1
     mountPath: /data
     readOnly: true
   command:
   - /usr/local/bin/bash
   - -c
   - |
     for word in $(</data/file.txt)
     do
     echo $word | md5sum | awk '{print $1}'
     done
```

### Observability

Check 1: Create Nginx Pod with Liveness HTTP Get Probe
Create a new Pod named nginx in the ca1 namespace using the nginx image. Ensure that the pod listens on port 80 and configure it with a Liveness HTTP GET probe with the following configuration:

Probe Type: httpGet
Path: /
Port: 80
Initial delay seconds: 10
Polling period seconds: 5

```bash
k run nginx --image=nginx --port 80 -n ca1 --dry-run=client -o yaml > nginx.yaml

piVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
  namespace: ca1
spec:
  containers:
  - image: nginx
    name: nginx
    ports:
    - containerPort: 80
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  livenessProbe:
    httpGet:
      path: /
      port: 80
    initialDelaySeconds: 10
    periodSeconds: 5
```

Check 2:
A Service in the hosting Namespace is not responding to requests. Determine which Service is not working and resolve the underlying issue so the Service begins responding to requests.

```bash
# edit HTTP port to 80

# or
cat << EOF > patch.yaml
spec:
  template:
    spec:
      containers:
      - name: web2
        readinessProbe:
          httpGet:
            port: 80
EOF
kubectl -n hosting patch deployments web2 --patch "$(cat patch.yaml)"
```

Check 3:
The ca2 namespace contains a set of pods. Pods labelled with app=test, or app=prod have been designed to log out a static list of numbers. Run a command that combines the pod logs for all pods that have the label app=prod and then get a total row count for the combined logs and save this result out to the file /home/ubuntu/combined-row-count-prod.txt.

```bash
k get pods -l app=prod -n ca2 -o=jsonpath="{range .items[*]}{.metadata.name}{'\n'}"
k logs test1 -n ca2 | wc -l

## multiple logs can be combined
k logs -n ca2 -l app=prod | wc -l > /home/ubuntu/combined-row-count-prod.txt
```

```bash
k run pod1 --image=busybox --labels="app=test" -- /bin/sh -c "echo 1"
k run pod2 --image=busybox --labels="app=prod" -- /bin/sh -c "echo 1"
k run pod3 --image=busybox --labels="app=prod" -- /bin/sh -c "echo 1"

k logs -l app=prod | wc -l

k delete po --all
k delete po -l app=prod
```

Check 3:
A pod named skynet has been deployed into the ca2 namespace. This pod has the following file /skynet/t2-specs.txt located within it, containing important information. You need to extract this file and save it to the following location /home/ubuntu/t2-specs.txt.

```bash
k cp skynet:/skynet/t2-specs.txt /home/ubuntu/t2-specs.txt -n ca2

# alternatively
k exec -n ca2 skynet -- cat /skynet/t2-specs.txt > /home/ubuntu/t2-specs.txt
```

```bash
k run logger --image=busybox --restart=Never -- /bin/sh -c 'echo "foo" > /tmp/foo.txt && sleep 3600'
k exec logger -- cat /tmp/foo.txt
k cp logger:/tmp/foo.txt foo.txt
```

Check 4:
Find the Pod that has the highest CPU utilization in the matrix namespace. Write the name of this pod into the following file: /home/ubuntu/max-cpu-podname.txt

```bash
k top po -n matrix
echo "agent4" > /home/ubuntu/max-cpu-podname.txt

# alternative
k top pods -n matrix --sort-by=cpu --no-headers=true | head -n1 | cut -d" " -f1 > /home/ubuntu/max-cpu-podname.txt
```

### Pod Design

Check 1: Create and Manage Deployments
Create a deployment named webapp in the zap namespace. Use the nginx:1.17.8 image and set the number of replicas initially to 2. Next, scale the current deployment up from 2 to 4. Finally, update the deployment to use the newer nginx:1.19.0 image.

```bash
k create deployment webapp --image=nginx:1.17.8 --replicas=2 -n zap
k scale --replicas=4 deploy webapp -n zap
k set image deployment webapp nginx=nginx:1.19.0 -n zap
```

Check 2: Create Pod Labels
Add an additional label app=cloudacademy to all pods currently running in the gzz namespace that have the label env=prod

```bash
k get -l env=prod po -n gzz
k label po bbox2 app=cloudacademy -n gzz
k label po bbox3 app=cloudacademy -n gzz

## can update multiple pods
k -n gzz label pods --selector env=prod app=cloudacademy
```

```bash
k run p1 --image=nginx --labels="env=prod"
k run p2 --image=nginx --labels="env=prod"
k run p3 --image=nginx --labels="env=test"

k get po -l env=prod
k label po -l env=prod app=cloudacademy
k get po -L env,app

k delete po -l env # delete all if env exists
```

Check 3: Rollback Deployment
The nginx container running within the cloudforce deployment in the fre namespace needs to be updated to use the nginx:1.19.0-perl image. Perform this deployment update and ensure that the command used to perform it is recorded in the tracked rollout history.

```bash
k edit deploy cloudforce -n fre --record
# edit image
k rollout history deploy cloudforce -n fre

k set image deployment/cloudforce nginx=nginx:1.19.0-perl --record -n fre


k create deploy cloudforce --image=nginx
k annotate deploy cloudforce kubernetes.io/change-cause="initial deploy"
k set image deploy cloudforce nginx=nginx:1.19.0
k annotate deploy cloudforce kubernetes.io/change-cause="set image to nginx:1.19.0"

# The nginx container running within the cloudforce deployment in the fre namespace needs to be updated to use the nginx:1.19.0-perl image. Perform this deployment update and ensure that the command used to perform it is recorded in the tracked rollout history.
kubectl -n fre set image deployment cloudforce nginx=nginx:1.19.0-perl
# To manage the deployment history, use the annotate command to create a message.
kubectl -n fre annotate deployment cloudforce kubernetes.io/change-cause="set image to nginx:1.19.0-perl" --overwrite=true
```

Check 4: Configure Pod AutoScaling
A deployment named eclipse has been created in the xx1 namespace. This deployment currently consists of 2 replicas. Configure this deployment to autoscale based on CPU utilisation. The autoscaling should be set for a minimum of 2, maximum of 4, and CPU usage of 65%.

```bash
k autoscale deployment eclipse --cpu-percent=65 --min=2 --max=4 -n xx1
```

Check 5: Create CronJob
Create a cronjob named matrix in the saas namespace. Use the radial/busyboxplus:curl image and set the schedule to `*/10 * * * *`. The job should run the following command: curl www.google.com

```bash
kubectl create cronjob matrix --image=radial/busyboxplus:curl --schedule="*/10 * * * *" -n saas -- curl www.google.com
```

Check 6: Filter and Sort Pods
Get a list of all pod names running in the rep namespace which have their colour label set to either orange, red, or yellow. The returned pod name list should contain only the pod names and nothing else. The pods names should be ordered by the cluster IP address assigned to each pod. The resulting pod name list should be saved out to the file /home/ubuntu/pod001

The following list is an example of the required output:

pod6
pod17
pod3
pod16
pod15
pod13

```bash
k get po -l 'colour in (orange, red, yellow)' -n rep -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'

k get po -l 'colour in (orange,red,yellow)' --sort-by=.status.podIP -n rep -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' > /home/ubuntu/pod001
```

```bash
k create deploy nginx --image=nginx --replicas=10
k get po --sort-by='{.status.podIP}' -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{.status.podIP}{'\n'}{end}"
k get po --sort-by='{.status.podIP}' -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" > names.txt
```

### Services & Networking

Check 1: Create and Configure a Basic Pod
Create a Pod in the red Namespace with the following configuration:

The Pod is named basic
The Pod uses the nginx:stable-alpine-perl image for its only container
Restart the Pod only OnFailure
Ensure port 80 is open to TCP traffic

```bash
k run basic --image=nginx:stable-alpine-perl --restart=OnFailure --port 80 -n red
```

Check 2: Expose Pod
Expose the Pod named basic in the red Namespace, ensuring it has the following settings:

Service name is cloudacademy-svc
Service port is 8080
Target port is 80
Service type is ClusterIP

```bash
k expose po basic --name=cloudacademy-svc --port=8080 --target-port=80 -n red

# kubectl expose po basic --port=8080 --target-port=80 -n red --dry-run=client -o yaml > cloudacademy-svc.yaml

# apiVersion: v1
# kind: Service
# metadata:
#   creationTimestamp: null
#   labels:
#     run: basic
#   name: cloudacademy-svc
#   namespace: red
# spec:
#   type: ClusterIP
#   ports:
#   - port: 8080
#     protocol: TCP
#     targetPort: 80
#   selector:
#     run: basic
# status:
#   loadBalancer: {}
```

Check 3: Expose existing Deployment
A Deployment named cloudforce has been created in the ca1 Namespace. You must now expose this Deployment as a NodePort based Service using the following settings:

Service name is cloudforce-svc
Service type is NodePort
Service port is 80
NodePort is 32080

```bash
k expose deploy cloudforce --type=NodePort --port 80 -n ca1 --dry-run=client -o yaml > nodesvc.yaml


apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: cloudforce
  name: cloudforce-svc
  namespace: ca1
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 32080
  selector:
    app: cloudforce
  type: NodePort
status:
  loadBalancer: {}
```

Check 4: Fix Networking Issue
A Deployment named t2 has been created in the skynet Namespace, and has been exposed as a ClusterIP based Service named t2-svc. The t2-svc Service when contacted should return a valid HTTP response, but unfortunately, this is currently not yet the case. Please investigate and fix the problem. When you have applied the fix, run the following command to save the HTTP response:

`kubectl run client -n skynet --image=appropriate/curl -it --rm --restart=Never -- curl http://t2-svc:8080 > /home/ubuntu/svc-output.txt`

```bash
# should update service selector
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cloudacademy
  name: t2-svc
  namespace: skynet
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 80
  selector:
    app: t2
  sessionAffinity: None
  type: ClusterIP
```

Check 5: Secure Pod Networking
The following two Pods have been created in the sec1 Namespace:

pod1 has the label app=test
pod2 has the label app=client
A NetworkPolicy named netpol1 has also been established in the sec1 Namespace but is currently blocking traffic sent from pod2 to pod1. Update the NetworkPolicy to ensure that pod2 can send traffic to pod1. Ensure the NetworkPolicy is still being applied to pod2 in your solution.

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: netpol1
  namespace: sec1
spec:
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: test #<-- change to client
  podSelector:
    matchLabels:
      app: test
  policyTypes:
  - Ingress


pod1IP=$(kubectl get pods pod1 -n sec1 -o jsonpath='{.status.podIP}')
kubectl -n sec1 exec -it pod2 -- ping $pod1IP
```

### State Persistent

Check 1: Persisting Data
Create a PersistentVolume named pv in the qq3 Namespace. The PersistentVolume must be configured with the following settings:

storageClassName: host
2Gi of storage capacity
Allow a single Node read-write access
Use a hostPath of /mnt/data
The PersistentVolume must be claimed by a PersistentVolumeClaim named pvc. The PersistentVolume must request 1Gi of storage capacity.

Lastly, create a Pod named persist with one redis container. The Pod must use the pvc PersistentVolumeClaim to mount a volume at /data.

```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv
  namespace: qq3
spec:
  storageClassName: host
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
  namespace: qq3
spec:
  storageClassName: host
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi


apiVersion: v1
kind: Pod
metadata:
  name: persist
  namespace: qq3
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: pvc
  containers:
    - name: task-pv-container
      image: redis
      volumeMounts:
        - mountPath: "/data"
          name: task-pv-storage
```

Check 2: Volume Mounts
The following manifest declares a single Pod named logger in the blah namespace. The logger Pod contains two containers c1 and c2. Before applying this manifest into the cluster, update it so that it declares a hostPath based Volume named vol1 with the host path set to /tmp/vol, and then mount this volume into both the c1 and c2 containers using the container directory /var/log/blah.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    env: prod
  name: logger
  namespace: blah
spec:
  containers:
    - image: bash
      name: c1
      command: ["/usr/local/bin/bash", "-c"]
      args:
        - ifconfig > /var/log/blah/data;
          sleep 3600;
    - image: bash
      name: c2
      command: ["/usr/local/bin/bash", "-c"]
      args:
        - sleep 3600;
```

```bash
apiVersion: v1
kind: Pod
metadata:
  labels:
    env: prod
  name: logger
  namespace: blah
spec:
  volumes:
  - name: vol1
    hostPath:
      path: /tmp/vol
      type: Directory
  containers:
  - image: bash
    name: c1
    command: ["/usr/local/bin/bash", "-c"]
    args:
    - ifconfig > /var/log/blah/data;
      sleep 3600;
    volumeMounts:
    - mountPath: /var/log/blah
      name: vol1
  - image: bash
    name: c2
    command: ["/usr/local/bin/bash", "-c"]
    args:
    - sleep 3600;
    volumeMounts:
    - mountPath: /var/log/blah
      name: vol1
```

## Challenges

### Kubernetes Certificate Challenge

Kubernetes Certification Practice Check 1: Created Specified Deployment
Create a deployment named chk1 in the cal namespace. Use the image nginx:1.15.12-alpine and set the number of replicas to 3. Finally, ensure the revision history limit is set to 50.

```bash
k create deploy chk1 --image=nginx:1.15.12-alpine --replicas=3 -n cal

# update - spec.revisionHistoryLimit
```

Kubernetes Certification Practice Check 2: Resolve Configuration Issues
The site deployment in the pwn namespace is supposed to be exposed to clients outside of the Kubernetes cluster by the sitelb service. However, requests sent to the service do not reach the deployment's pods. Resolve the service configuration issue so the requests sent to the service do reach the deployment's pods.

```bash
# update svc selector
```

Kubernetes Certification Practice Check 3: Highest CPU Pod
Write the name of the pod in zz8 namespace consuming the most CPU to /home/ubuntu/hcp001. The content of the file should be only the name of the Pod and nothing more.

```bash
k top po -n zz8
echo fnsoe-ah3na38s-zy3kx > /home/ubuntu/hcp001
```

Kubernetes Certification Practice Check 4: Pod Secret
In the sjq namespace, create a secret named xh8jqk7z that stores a generic secret with the key of tkn and the value of hy8szK2iu. Create a pod named server using the httpd:2.4.39-alpine image and give the pod's container access to the tkn key in the xh8jqk7z secret through an environment variable named SECRET_TKN.

```bash
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: server
  name: server
  namespace: sjq
spec:
  containers:
  - image: httpd:2.4.39-alpine
    name: server
    resources: {}
    env:
    - name: SECRET_TKN
      valueFrom:
        secretKeyRef:
          name: xh8jqk7z
          key: tkn
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

### Certified Kubernetes Application Developer (CKAD) Challenge

CKAD Check 1: Service Account
Create a service account named inspector in the dwx7eq namespace. Then create a deployment named calins in the same namespace. Use the image busybox:1.31.1 for the only pod container and pass the arguments sleep and 24h to the container. Set the number of replicas to 1. Lastly, make sure that the deployments' pod is using the inspector service account.

```bash
k create sa inspector -n dwx7eq
k create deploy calins --image=busybox:1.31.1 --replicas=1 --dry-run=client -o yaml -- sleep 86400 > calins.yaml
# update service account name
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: calins
  name: calins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: calins
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: calins
    spec:
      serviceAccountName: inspector
      containers:
      - command:
        - sleep
        - "86400"
        image: busybox:1.31.1
        name: busybox
        resources: {}
```

CKAD Check 2: Evictions
The mission-critical deployment in the bk0c2d namespace has been getting evicted when the Kubernetes cluster is consuming a lot of memory. Modify the deployment so that it will not be evicted when the cluster is under memory pressure unless there are higher priority pods running in the cluster (Guaranteed Quality of Service). It is known that the container for the deployment's pod requires and will not use more than 200 milliCPU (200m) and 200 mebibytes (200Mi) of memory.

```bash
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "This priority class should be used for XYZ service pods only."

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "4"
  creationTimestamp: "2023-09-14T03:17:46Z"
  generation: 4
  labels:
    app: mission-critical
  name: mission-critical
  namespace: bk0c2d
  resourceVersion: "121463"
  uid: fa2b8ade-2576-4dcc-a16d-352121a04ea5
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: mission-critical
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: mission-critical
    spec:
      containers:
      - env:
        - name: MASTER
          value: "true"
        image: redis:5.0.7
        imagePullPolicy: IfNotPresent
        name: mission-critical
        ports:
        - containerPort: 6379
          protocol: TCP
        resources:
          limits: ### <--- updated
            cpu: 200m
            memory: 200Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /redis-master-data
          name: data
      dnsPolicy: ClusterFirst
      priorityClassName: high-priority ### <-- updated
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: data
```

A legacy application runs via a deployment in the zuc0co namespace. The deployment's pod uses a multi-container pod to convert the legacy application's raw metric output into a format that can be consumed by a metric aggregation system. However, the data is currently lost every time the pod is deleted. Modify the deployment to use a persistent volume claim with 2GiB of storage and access mode of ReadWriteOnce so the data is persisted if the pod is deleted.

```bash
## before
apiVersion: v1
kind: PersistentVolume
metadata:
  name: legacy-pv
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: legacy-pvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"legacy"},"name":"legacy","namespace":"zuc0co"},"spec":{"replicas":1,"selector":{"matchLabels":{"app":"legacy"}},"template":{"metadata":{"labels":{"app":"legacy"}},"spec":{"containers":[{"args":["while true; do date \u003e /metrics/raw.txt; top -n 1 -b \u003e\u003e /metrics/raw.txt; sleep 5; done"],"command":["/bin/sh","-c"],"image":"alpine:3.9.2","name":"app","volumeMounts":[{"mountPath":"/metrics","name":"metrics"}]},{"args":["while true; do date=$(head -1 /metrics/raw.txt); memory=$(head -2 /metrics/raw.txt | tail -1 | grep -o -E '\\d+\\w' | head -1); cpu=$(head -3 /metrics/raw.txt | tail -1 | grep -o -E '\\d+%' | head -1); echo \"{\\\"date\\\":\\\"$date\\\",\\\"memory\\\":\\\"$memory\\\",\\\"cpu\\\":\\\"$cpu\\\"}\" \u003e\u003e /metrics/adapted.json; sleep 5; done"],"command":["/bin/sh","-c"],"image":"httpd:2.4.38-alpine","name":"adapter","volumeMounts":[{"mountPath":"/metrics","name":"metrics"}]}],"volumes":[{"emptyDir":null,"name":"metrics"}]}}}}
  creationTimestamp: "2023-09-14T02:33:22Z"
  generation: 1
  labels:
    app: legacy
  name: legacy
  namespace: zuc0co
  resourceVersion: "118593"
  uid: ef9ce677-ff74-4097-bf4d-45540fe5ce73
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: legacy
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: legacy
    spec:
      containers:
      - args:
        - while true; do date > /metrics/raw.txt; top -n 1 -b >> /metrics/raw.txt;
          sleep 5; done
        command:
        - /bin/sh
        - -c
        image: alpine:3.9.2
        imagePullPolicy: IfNotPresent
        name: app
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /metrics
          name: metrics
      - args:
        - while true; do date=$(head -1 /metrics/raw.txt); memory=$(head -2 /metrics/raw.txt
          | tail -1 | grep -o -E '\d+\w' | head -1); cpu=$(head -3 /metrics/raw.txt
          | tail -1 | grep -o -E '\d+%' | head -1); echo "{\"date\":\"$date\",\"memory\":\"$memory\",\"cpu\":\"$cpu\"}"
          >> /metrics/adapted.json; sleep 5; done
        command:
        - /bin/sh
        - -c
        image: httpd:2.4.38-alpine
        imagePullPolicy: IfNotPresent
        name: adapter
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /metrics
          name: metrics
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: metrics

##
apiVersion: v1
kind: PersistentVolume
metadata:
  name: legacy-pv
  namespace: zuc0co
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: legacy-pvc
  namespace: zuc0co
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi


apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"legacy"},"name":"legacy","namespace":"zuc0co"},"spec":{"replicas":1,"selector":{"matchLabels":{"app":"legacy"}},"template":{"metadata":{"labels":{"app":"legacy"}},"spec":{"containers":[{"args":["while true; do date \u003e /metrics/raw.txt; top -n 1 -b \u003e\u003e /metrics/raw.txt; sleep 5; done"],"command":["/bin/sh","-c"],"image":"alpine:3.9.2","name":"app","volumeMounts":[{"mountPath":"/metrics","name":"metrics"}]},{"args":["while true; do date=$(head -1 /metrics/raw.txt); memory=$(head -2 /metrics/raw.txt | tail -1 | grep -o -E '\\d+\\w' | head -1); cpu=$(head -3 /metrics/raw.txt | tail -1 | grep -o -E '\\d+%' | head -1); echo \"{\\\"date\\\":\\\"$date\\\",\\\"memory\\\":\\\"$memory\\\",\\\"cpu\\\":\\\"$cpu\\\"}\" \u003e\u003e /metrics/adapted.json; sleep 5; done"],"command":["/bin/sh","-c"],"image":"httpd:2.4.38-alpine","name":"adapter","volumeMounts":[{"mountPath":"/metrics","name":"metrics"}]}],"volumes":[{"emptyDir":null,"name":"metrics"}]}}}}
  creationTimestamp: "2023-09-14T02:33:22Z"
  generation: 1
  labels:
    app: legacy
  name: legacy
  namespace: zuc0co
  resourceVersion: "118593"
  uid: ef9ce677-ff74-4097-bf4d-45540fe5ce73
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: legacy
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: legacy
    spec:
      containers:
      - args:
        - while true; do date > /metrics/raw.txt; top -n 1 -b >> /metrics/raw.txt;
          sleep 5; done
        command:
        - /bin/sh
        - -c
        image: alpine:3.9.2
        imagePullPolicy: IfNotPresent
        name: app
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /metrics
          name: metrics
      - args:
        - while true; do date=$(head -1 /metrics/raw.txt); memory=$(head -2 /metrics/raw.txt
          | tail -1 | grep -o -E '\d+\w' | head -1); cpu=$(head -3 /metrics/raw.txt
          | tail -1 | grep -o -E '\d+%' | head -1); echo "{\"date\":\"$date\",\"memory\":\"$memory\",\"cpu\":\"$cpu\"}"
          >> /metrics/adapted.json; sleep 5; done
        command:
        - /bin/sh
        - -c
        image: httpd:2.4.38-alpine
        imagePullPolicy: IfNotPresent
        name: adapter
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /metrics
          name: metrics
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - name: metrics
        persistentVolumeClaim:
          claimName: legacy-pvc
```

CKAD Check 4: Multi-Container Pattern
Write the name of the multi-container pod design pattern used by the pod in the previous task to a file at /home/ubuntu/mcpod.

```bash
echo adapter > /home/ubuntu/mcpod
```

### Cert Prep: Certified Kubernetes Application Developer (CKAD)

```bash

```
