## Prep

- https://kubernetes.io/docs
- https://helm.sh/docs

```bash
alias k=kubectl
k completion --help
helm completion bash --help

echo 'alise k=kubectl' >> ~/.bash_profile
echo 'source <(kubectl completion bash)' >> ~/.bash_profile
echo 'source <(helm completion bash)' >> ~/.bash_profile
```

## Kubernetes Pod Design for Application Developers

### Labels, Selectors, and Annotations

```bash
k create namespace labels
k config set-context $(k config current-context) --namespace=labels

cat > file.txt <<EOL
line 1, ${kernel}
line 2,
line 3, ${distro}
line 4 line
...
EOL

# Write the manifest file
cat > pod-labels.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: red-frontend
  # namespace: labels # declare namespace in metadata
  labels: # labels mapping in metadata
    color: red
    tier: frontend
  annotations: # Example annotation
    Lab: Kubernetes Pod Design for Application Developers
spec:
  containers:
  - image: httpd:2.4.38
    name: web-server
---
apiVersion: v1
kind: Pod
metadata:
  name: green-frontend
  # namespace: labels
  labels:
    color: green
    tier: frontend
spec:
  containers:
  - image: httpd:2.4.38
    name: web-server
---
apiVersion: v1
kind: Pod
metadata:
  name: red-backend
  # namespace: labels
  labels:
    color: red
    tier: backend
spec:
  containers:
  - image: postgres:11.2-alpine
    name: db
---
apiVersion: v1
kind: Pod
metadata:
  name: blue-backend
  # namespace: labels
  labels:
    color: blue
    tier: backend
spec:
  containers:
  - image: postgres:11.2-alpine
    name: db
EOF
```

```bash
# Create the Pods
k create -f pod-labels.yaml

k get po -L color,tier

k get po -L color,tier -l color
k get po -L color,tier -l '!color'
k get po -L color,tier -l 'color=red'
k get po -L color,tier -l 'color=red,tier!=frontend'
k get po -L color,tier -l 'color in (blue,green)'

k label po red-frontend foo=bar
k label po red-frontend foo-

k annotate po red-frontend description='my annotation'
k annotate po red-frontend description-
k annotate po red-frontend Lab-

k describe po red-frontend | grep Annotations -A 2
k get po red-frontend -o yaml | more
```

### Deployments

```bash
k create ns deployment
k config set-context $(k config current-context) --namespace=deployment

k create deployment --image=httpd:2.4.38 web-server --dry-run=client -o yaml

# max unavailable: The maximum number of Pods that can be unavailable during the update.
# max surge: The maximum number of Pods that can be scheduled above the desired number of Pods.

k scale deployment web-server --replicas=6

k rollout history deploy web-server

k edit deployment web-server --record

k set image deploy web-server httpd=httpd:2.4.38-alpine --record

k rollout undo deploy web-server

k expose deploy web-server --type=LoadBalancer --port=80
k expose deploy web-server --type=NodePort --port=80 --dry-run=client -o yaml
```

### Jobs and CronJobs

- backoffLimit: Number of times a Job will retry before marking a Job as failed
- completions: Number of Pod completions the Job needs before being considered a success
- parallelism: Number of Pods the Job is allowed to run in parallel
- spec.template.spec.restartPolicy: Job Pods default to never attempting to restart. Instead, the Job is responsible for managing the restart of failed Pods.

- The activeDeadlineSeconds and ttlSecondsAfterFinished are useful for automatically terminating and deleting Jobs.
- pods won't be deleted, ttlSecondsAfterFinished can free you from manually cleaning up the Pods

```bash
k create ns jobs
k config set-context $(k config current-context) --namespace=jobs

k create job one-off --image=alpine -- sleep 30

k get job one-off -o yaml | more
```

```bash
cat << 'EOF' > pod-fail.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pod-fail
spec:
  backoffLimit: 3
  completions: 6
  parallelism: 2
  template:
    spec:
      containers:
      - image: alpine
        name: fail
        command: ['sleep 20 && exit 1']
      restartPolicy: Never
EOF

k create -f pod-fail.

k create cronjob cronjob-example --image=alpine --schedule="*/1 * * * *" -- date
k create cronjob cronjob-example --image=alpine --schedule="*/1 * * * *" --restart=Never --dry-run=client -o yaml -- date

k describe cj cronjob-example

# apiVersion: batch/v1
# kind: CronJob
# metadata:
#   creationTimestamp: null
#   name: cronjob-example
# spec:
#   jobTemplate:
#     metadata:
#       creationTimestamp: null
#       name: cronjob-example
#     spec:
#       ttlSecondsAfterFinished: 100
#       template:
#         metadata:
#           creationTimestamp: null
#         spec:
#           containers:
#           - command:
#             - date
#             image: alpine
#             name: cronjob-example
#             resources: {}
#           restartPolicy: Never
#   schedule: '*/1 * * * *'
# status: {}
```

## Kubernetes Observability

### Logging

```bash
k create namespace logs
k config set-context $(k config current-context) --namespace=logs
```

#### Understanding Container Logging in Kubernetes

```bash
cat << 'EOF' > pod-logs.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: logs
  name: pod-logs
spec:
  containers:
  - name: server
    image: busybox:1.30.1
    ports:
    - containerPort: 8888
    # Listen on port 8888
    command: ["/bin/sh", "-c"]
    # -v for verbose mode
    args: ["nc -p 8888 -v -lke echo Received request"]
    readinessProbe:
      tcpSocket:
        port: 8888
  - name: client
    image: busybox:1.30.1
    # Send requests to server every 5 seconds
    command: ["/bin/sh", "-c"]
    args: ["while true; do sleep 5; nc localhost 8888; done"]
EOF
k create -f pod-logs.yaml

k logs pod-logs server
k logs -f --tail=1 --timestamps pod-logs client


cat << 'EOF' > pod-webserver.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: logs
  name: webserver-logs
spec:
  containers:
  - name: server
    image: httpd:2.4.38-alpine
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /
        port: 80
EOF
k create -f pod-webserver.yaml
k expose pod webserver-logs --type=LoadBalancer # if --port not specified, use container port
k expose pod webserver-logs --type=NodePort

k exec webserver-logs -- tail -10 conf/httpd.conf
#
# Note: The following must must be present to support
#       starting without SSL on platforms with no /dev/random equivalent
#       but a statically compiled-in mod_ssl.
#
<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>

k cp webserver-logs:conf/httpd.conf httpd.conf
```

#### Kubernetes Logging Using a Logging Agent and the Sidecar Pattern

```bash
s3_bucket=$(aws s3api list-buckets --query "Buckets[].Name" --output table | grep logs | tr -d \|)
echo $s3_bucket

cat << EOF > fluentd-sidecar-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    # First log source (tailing a file at /var/log/1.log)
    <source>
      @type tail
      format none
      path /var/log/1.log
      pos_file /var/log/1.log.pos
      tag count.format1
    </source>

    # Second log source (tailing a file at /var/log/2.log)
    <source>
      @type tail
      format none
      path /var/log/2.log
      pos_file /var/log/2.log.pos
      tag count.format2
    </source>

    # S3 output configuration (Store files every minute in the bucket's logs/ folder)
    <match **>
      @type s3

      s3_bucket $s3_bucket
      s3_region us-west-2
      path logs/
      buffer_path /var/log/
      store_as text
      time_slice_format %Y%m%d%H%M
      time_slice_wait 1m

      <instance_profile_credentials>
      </instance_profile_credentials>
    </match>
EOF
k create -f fluentd-sidecar-config.yaml

cat << 'EOF' > pod-counter.yaml
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - >
      i=0;
      while true;
      do
        # Write two log files along with the date and a counter
        # every second
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done
    # Mount the log directory /var/log using a volume
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: count-agent
    image: lrakai/fluentd-s3:latest
    env:
    - name: FLUENTD_ARGS
      value: -c /fluentd/etc/fluent.conf
    # Mount the log directory /var/log using a volume
    # and the config file
    volumeMounts:
    - name: varlog
      mountPath: /var/log
    - name: config-volume
      mountPath: /fluentd/etc
  # Use host network to allow sidecar access to IAM instance profile credentials
  hostNetwork: true
  # Declare volumes for log directory and ConfigMap
  volumes:
  - name: varlog
    emptyDir: {}
  - name: config-volume
    configMap:
      name: fluentd-config
EOF
k create -f pod-counter.yaml
```

```bash
## create a simple sidecar container
# i=1; while true; do echo "run $i"; ((i+=1)); sleep 2; done
k run sidecar --image=busybox --dry-run=client -o yaml > sidecar.yaml

# apiVersion: v1
# kind: Pod
# metadata:
#   labels:
#     run: sidecar
#   name: sidecar
# spec:
#   volumes:
#     - name: sidecar-storage
#       emptyDir: {}
#   containers:
#     - image: busybox
#       name: main
#       command:
#         - sh
#         - -c
#         - 'i=1; while true; do echo "run $i" >> /tmp/log.log; i=$((i+1)); sleep 2; done'
#       volumeMounts:
#         - name: sidecar-storage
#           mountPath: /tmp
#     - image: busybox
#       name: sidecar
#       command:
#         - sh
#         - -c
#         - "while true; do tail /tmp/log.log -n 1; sleep 2; done"
#       volumeMounts:
#         - name: sidecar-storage
#           mountPath: /tmp
```

### Monitoring and Debugging

#### Using Probes to Better Understand Pod Health

- Readiness probes are used to detect when a Pod is unable to serve traffic. When the Pod is accessed through a Kubernetes Service, the Service will not serve traffic to any Pods that have a failing readiness probe.
- Liveness probes are used to detect when a Pod fails to make progress after entering a broken state, such as deadlock. ... by detecting a Pod is in a broken state allows Kubernetes to restart the Pod
- Startup probes are used when an application starts slowly and may otherwise be killed due to failed liveness probes. The startup probe runs before both readiness and liveness probes. The startup probe can be configured with a startup time that is longer than the time needed to detect a broken state for a container after it has started.

- exec: Issue a command in the container. If the exit code is zero the container is a success, otherwise it is a failed probe.
- httpGet: Send a HTTP GET request to the container at a specified path and port. If the HTTP response status code is a 2xx or 3xx then the container is a success, otherwise, it is a failure.
- tcpSocket: Attempt to open a socket to the container on a specified port. If the connection cannot be established, the probe fails.

```bash
k explain pod.spec.containers.readinessProbe

cat << 'EOF' > pod-readiness.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: readiness
  name: readiness-http
spec:
  containers:
  - name: readiness
    image: httpd:2.4.38-alpine
    ports:
    - containerPort: 80
    # Sleep for 30 seconds before starting the server
    command: ["/bin/sh","-c"]
    args: ["sleep 30 && httpd-foreground"]
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 3
EOF
k create -f pod-readiness.yaml

k exec readiness-http -- pkill httpd


cat << 'EOF' > pod-liveness.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-tcp
spec:
  containers:
  - name: liveness
    image: busybox:1.30.1
    ports:
    - containerPort: 8888
    # Listen on port 8888 for 30 seconds, then sleep
    command: ["/bin/sh", "-c"]
    args: ["timeout 30 nc -p 8888 -lke echo hi && sleep 600"]
    livenessProbe:
      tcpSocket:
        port: 8888
      initialDelaySeconds: 3
      periodSeconds: 5
EOF
k create -f pod-liveness.yaml

k delete -f pod-readiness.yaml
k delete -f pod-liveness.yaml
```

#### Monitoring Kubernetes Applications

```bash
k get pods -A

k get events -n default
k get events -n default -o wide

k top node # or pod
k top pods -n kube-system
k top pod -n kube-system --containers
k top pod -n kube-system --containers -l k8s-app=kube-dns

k top po -n kube-system --containers --sort-by=cpu
k logs kube-proxy-d2ltl -n kube-system --tail=10
```

## Mastering Kubernetes Pod Configuration

### Defining Resource Requirements

```bash
k run load --image cloudacademydevops/stress -- -cpus "2"

k top po
k top no

k apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: load-limited
spec:
  containers:
  - name: cpu-load-limited
    image: cloudacademydevops/stress
    args:
    - cpus
    - "2"
    resources:
      limits:
        cpu: "0.5"
        memory: "20Mi"
      requests:
        cpu: "0.35"
        memory: "10Mi"
EOF
```

It's important to note that the scheduler doesn't consider the actual resource utilization of the node. Rather, it bases its decision upon the sum of container resource requests on the node. For example, if a container requests all the CPU of a node but is actually 0% CPU, the scheduler would treat the node as not having any CPU available.

```bash
k describe nodes | grep --after-context=5 "Non-terminated Pods"
# Non-terminated Pods:          (4 in total)
#   Namespace                   Name                  CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
#   ---------                   ----                  ------------  ----------  ---------------  -------------  ---
#   default                     load                  0 (0%)        0 (0%)      0 (0%)           0 (0%)         12m
```

Resource requests/limits are not counted for `load` container although it consumes almost all CPU of a node.
The `load-limit` container may be scheduled in a different node but it is by change.

Containers that exceed their memory limits will be terminated and restarted if possible.
Containers that exceed their memory request may be evicted when the node runs out of memory.
Containers that exceed their CPU limits may be allowed to exceed the limit depending on the other Pods on the node.
Containers that exceed their CPU limits won't be terminated.

### Security Contexts

```bash
k explain pod.spec.securityContext | more
k explain pod.spec.containers.securityContext | more

cat << EOF > pod-no-security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-test-1
spec:
  containers:
  - image: busybox:1.30.1
    name: busybox
    args:
    - sleep
    - "3600"
EOF
kubectl create -f pod-no-security-context.yaml
kubectl exec security-context-test-1 -- ls /dev

kubectl delete -f pod-no-security-context.yaml

cat > pod-privileged.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: security-context-test-2
spec:
  containers:
  - image: busybox:1.30.1
    name: busybox
    args:
    - sleep
    - "3600"
    securityContext:
      privileged: true
EOF
kubectl create -f pod-privileged.yaml
kubectl exec security-context-test-2 -- ls /dev
# BE CAREFUL!! all of the host devices are available including the host file system disk nvme0n1p1

kubectl delete -f pod-privileged.yaml

cat << EOF > pod-runas.yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-test-3
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - image: busybox:1.30.1
    name: busybox
    args:
    - sleep
    - "3600"
    securityContext:
      runAsUser: 2000
      readOnlyRootFilesystem: true
EOF
kubectl create -f pod-runas.yaml

kubectl exec security-context-test-3 -it -- /bin/sh

touch /tmp/test-file
# touch: /tmp/test-file: Read-only file system

# best practice is put read only root file system and attach a volume for a file that requries modification
```

### Persistent Data

```bash
# Create namespace
k create namespace persistence
# Set namespace as the default for the current context
k config set-context $(k config current-context) --namespace=persistence

cat << 'EOF' > pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: db-data
spec:
  # Only one node can mount the volume in Read/Write
  # mode at a time
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF
k create -f pvc.yaml

cat << 'EOF' > db.yaml
apiVersion: v1
kind: Pod
metadata:
  name: db
spec:
  containers:
  - image: mongo:4.0.6
    name: mongodb
    # Mount as volume
    volumeMounts:
    - name: data
      mountPath: /data/db
    ports:
    - containerPort: 27017
      protocol: TCP
  volumes:
  - name: data
    # Declare the PVC to use for the volume
    persistentVolumeClaim:
      claimName: db-data
EOF
k create -f db.yaml

k exec db -it -- mongo testdb --quiet --eval \
  'db.messages.insert({"message": "I was here"}); db.messages.findOne().message'

k delete -f db.yaml
k create -f db.yaml

k exec db -it -- mongo testdb --quiet --eval 'db.messages.findOne().message'
```

```bash
# create a PV/PVC and associated with a pod
minikube ssh -n minikube-m02
sudo sh -c "echo 'Hello from Kubernetes storage' > /data/pv0001/index.html"
cat /data/pv0001/index.html

cat > pv-example.yaml <<EOL
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /data/pv0001/
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pvc
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: task-pod
spec:
  volumes:
  - name: task-volume
    persistentVolumeClaim:
      claimName: task-pvc
  containers:
  - image: nginx
    name: task-container
    ports:
    - containerPort: 80
      name: "http-server"
    volumeMounts:
    - name: task-volume
      mountPath: "/usr/share/nginx/html"
EOL

k exec -it pv-pod -- /bin/bash

k exec -it pv-pod -- ls /usr/share/nginx/html

# dynamic provisioning
# with only specifying storageClassName in pvc, PV will be provisioned
```

### Config Maps and Secrets

#### Configuring Pods using Data Stored in ConfigMaps

```bash
# Create namespace
k create namespace configmaps
# Set namespace as the default for the current context
k config set-context $(k config current-context) --namespace=configmaps

k create cm app-config --from-literal=DB_NAME=testdb --from-literal=COLLECTION_NAME=messages
k get cm app-config -o yaml

cat << 'EOF' > pod-configmap.yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm
spec:
  containers:
  - image: busybox
    name: test
    # Mount as volume
    volumeMounts:
    - name: config
      mountPath: /config
    ports:
    - containerPort: 27017
      protocol: TCP
  volumes:
  - name: config
    # Declare the configMap to use for the volume
    configMap:
      name: app-config
EOF
k create -f pod-configmap.yaml

k exec db -it -- ls /config
# COLLECTION_NAME  DB_NAME
k exec db -- cat /config/DB_NAME && echo

k explain pod.spec.containers.envFrom.configMapRef
```

```bash
## create config map and associate with a pod in 3 ways
k create cm app-config --from-literal=DB_NAME=testdb --from-literal=COLLECTION_NAME=messages

cat > cm-trial.yaml <<EOL
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_NAME: testdb
  COLLECTION_NAME: messages
---
apiVersion: v1
kind: Pod
metadata:
  name: cm-pod
spec:
  volumes:
  - name: cm-vol
    configMap:
      name: app-config
  containers:
  - image: busybox
    name: cm-container
    command: ["sleep", "3600"]
    env:
    - name: DB_NAME_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_NAME
    envFrom:
    - configMapRef:
        name: app-config
    volumeMounts:
    - name: cm-vol
      mountPath: /tmp
EOL

k exec cm-pod -- cat /tmp/DB_NAME
k exec cm-pod -- env
```

#### Storing and Accessing Sensitive Information Using Kubernetes Secrets

```bash
# Create namespace
k create namespace secrets
# Set namespace as the default for the current context
k config set-context $(k config current-context) --namespace=secrets

k create secret generic app-secret --from-literal=password=123457
k get secret app-secret -o yaml
# echo MTIzNDU3 | base64 --decode
# kubectl get secret app-secret -o jsonpath="{.data.password}" \
#   | base64 --decode \
#   && echo

cat << EOF > pod-secret.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret
spec:
  containers:
  - image: busybox:1.30.1
    name: busybox
    args:
    - sleep
    - "3600"
    env:
    - name: PASSWORD      # Name of environment variable
      valueFrom:
        secretKeyRef:
          name: app-secret  # Name of secret
          key: password     # Name of secret key
EOF
k create -f pod-secret.yaml

k exec pod-secret -- /bin/sh -c 'echo $PASSWORD'
```

```bash
## create secret and associate with a pod in 3 ways
cat > secret-trial.yaml <<EOL
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  secret: cGFzc3dvcmQ=
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  volumes:
  - name: secret-vol
    secret:
      secretName: app-secret
  containers:
  - image: busybox
    name: secret-container
    command: ["sleep", "3600"]
    env:
    - name: secret-env
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: secret
    envFrom:
    - secretRef:
        name: app-secret
    volumeMounts:
    - name: secret-vol
      mountPath: /tmp
EOL

k exec secret-pod -- env
k exec secret-pod -- cat /tmp/secret
```

### Service Accounts

```bash
# Create namespace
k create namespace serviceaccounts
# Set namespace as the default for the current context
k config set-context $(k config current-context) --namespace=serviceaccounts

k run default-pod --image=mongo:4.0.6
k get pod default-pod -o yaml | more

k create sa app-sa
cat << 'EOF' > pod-custom-sa.yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-sa-pod
spec:
  containers:
  - image: mongo:4.0.6
    name: mongodb
  serviceAccount: app-sa
EOF
k create -f pod-custom-sa.yaml
```

## Further Topics

### Utilizing Ephemeral Volume Type in Kubernetes

- ephemeral volume is tied to the lifetime of pod, not container
- e.g. it won't be wiped out if the container is restarted

```bash
# Create namespace
k create namespace ephemeral
# Set namespace as the default for the current context
k config set-context $(k config current-context) --namespace=ephemeral

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: coin-toss
spec:
  containers:
  - name: coin-toss
    image: busybox:1.33.1
    command: ["/bin/sh", "-c"]
    args:
    - >
      while true;
      do
        # Record coint tosses
        if [[ $(($RANDOM % 2)) -eq 0 ]]; then echo Heads; else echo Tails; fi >> /var/log/tosses.txt;
        sleep 1;
      done
    # Mount the log directory /var/log using a volume
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  # Declare log directory volume an emptyDir ephemeral volume
  volumes:
  - name: varlog
    emptyDir: {}
EOF

k exec coin-toss -- cat /var/log/tosses.txt | wc -l

# can add resource limit, evicted if exceeds limits
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: cache
spec:
  containers:
  - name: cache
    image: redis:6.2.5-alpine
    resources:
      requests:
        ephemeral-storage: "1Ki"
      limits:
        ephemeral-storage: "1Ki"
    volumeMounts:
    - name: ephemeral
      mountPath: "/data"
  volumes:
    - name: ephemeral
      emptyDir:
        sizeLimit: 1Ki
EOF
```

### Control Kubernetes Network Traffic with Network Policies

- define rules that select what pods, namespaces, or IP address ranges the policy applies to
- no ingress or egress policy types - allow all
- egress policy type but no egress type - block all egress

```bash
# k get netpol deny-metadata -o yaml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-metadata
spec:
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
  podSelector: {}
  policyTypes:
  - Egress

# k describe netpol deny-metadata
Name:         deny-metadata
Namespace:    default
Created on:   2023-03-25 06:19:03 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Not affecting ingress traffic
  Allowing egress traffic:
    To Port: <any> (traffic allowed to all ports)
    To:
      IPBlock:
        CIDR: 0.0.0.0/0
        Except: 169.254.169.254/32
  Policy Types: Egress

k run busybox --image=busybox --rm -it /bin/sh
$ wget https://google.com # works
$ wget 169.254.169.254 # won't work

k create namespace test
k run busybox --image=busybox --rm -it -n test /bin/sh
$ wget 169.254.169.254 # works

# can be dangerous
role=$(wget -qO- 169.254.169.254/latest/meta-data/iam/security-credentials)
wget -qO- 169.254.169.254/latest/meta-data/iam/security-credentials/$role

##
cat > app-policy.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-tiers
  namespace: test
spec:
  podSelector:
    matchLabels:
      app-tier: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app-tier: cache
    ports:
    - port: 80
EOF
k create -f app-policy.yaml

k run web-server -n test -l app-tier=web --image=nginx:1.15.1 --port 80

# Get the web server pod's IP address
web_ip=$(kubectl get pod -n test -o jsonpath='{.items[0].status.podIP}')
kubectl run busybox -n test -l app-tier=cache --image=busybox --env="web_ip=$web_ip" --rm -it /bin/sh
wget $web_ip

# fails
kubectl run busybox -n test --image=busybox --env="web_ip=$web_ip" --rm -it /bin/sh
wget $web_ip
```

### Deploy a Stateful Application in Kubernetes Cluster

#### Inspecting the Kubernetes Cluster

- calico: The container network used to connect each node to every other node in the cluster. Calico also supports network policy. Calico is one of many possible container networks that can be used by Kubernetes.
- coredns: Provides DNS services to nodes in the cluster
- etcd: The primary data store of all cluster state
- kube-apiserver: The REST API server for managing the Kubernetes cluster
- kube-controller-manager: Manager of all of the controllers in the cluster that monitor and change the cluster state when necessary
- kube-proxy: Network proxy that runs on each node
- kube-scheduler: Control plane process which assigns Pods to Nodes
- metrics-server: Not an essential component of a Kubernetes cluster but it is used in this lab to provide metrics for viewing in the Kubernetes dashboard.
- ebs-csi: Not an essential component of a Kubernetes cluster but is used to manage the lifecycle of Amazon EBS volumes for persistent volumes.

```bash
kubectl describe nodes -l node-role.kubernetes.io/control-plane | more
# Taints - node-role.kubernetes.io/master:NoSchedule
# => no pod will be scheduled unless toleration of node-role.kubernetes.io/master is declared
```

#### Deploying a Stateful Application in the Kubernetes Cluster

- ConfigMaps: A type of Kubernetes resource that is used to decouple configuration artifacts from image content to keep containerized applications portable. The configuration data is stored as key-value pairs.
- Headless Service: A headless service is a Kubernetes service resource that won't load balance behind a single service IP. Instead, a headless service returns a list of DNS records that point directly to the pods that back the service. A headless service is defined by declaring the clusterIP property in a service spec and setting the value to None. StatefulSets currently require a headless service to identify pods in the cluster network.
- Stateful Sets: Similar to Deployments in Kubernetes, StatefulSets manage the deployment and scaling of pods given a container spec.StatefulSets differ from Deployments in that the Pods in a stateful set are not interchangeable. Each pod in a StatefulSet has a persistent identifier that it maintains across any rescheduling. The pods in a StatefulSet are also ordered. This provides a guarantee that one pod can be created before following pods. In this lab, this is useful for ensuring the MySQL primary is provisioned first.
- PersistentVolumes (PVs) and PersistentVolumeClaims (PVCs): PVs are Kubernetes resources that represent storage in the cluster. Unlike regular Volumes which exist only until while containing pod exists, PVs do not have a lifetime connected to a pod. Thus, they can be used by multiple pods over time, or even at the same time. Different types of storage can be used by PVs including NFS, iSCSI, and cloud-provided storage volumes, such as AWS EBS volumes. Pods claim PV resources through PVCs.
- MySQL replication: This lab uses a single primary, asynchronous replication scheme for MySQL. All database writes are handled by a single primary. The database replicas asynchronously synchronize with the primary. This means the primary will not wait for the data to be copied onto the replicas. This can improve the performance of the primary at the expense of having replicas that are not always exact copies of the primary. Many applications can tolerate slight differences in the data and are able to improve the performance of database read workloads by allowing clients to read from the replicas.

```bash
cat <<EOF > mysql-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql
  labels:
    app: mysql
data:
  master.cnf: |
   # Apply this config only on the primary.
   [mysqld]
   log-bin
  slave.cnf: |
    # Apply this config only on replicas.
    [mysqld]
    super-read-only
EOF

cat <<EOF > mysql-services.yaml
# Headless service for stable DNS entries of StatefulSet members.
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  ports:
  - name: mysql
    port: 3306
  clusterIP: None
  selector:
    app: mysql
---
# Client service for connecting to any MySQL instance for reads.
# For writes, you must instead connect to the primary: mysql-0.mysql.
apiVersion: v1
kind: Service
metadata:
  name: mysql-read
  labels:
    app: mysql
spec:
  ports:
  - name: mysql
    port: 3306
  selector:
    app: mysql
EOF
# A headless service (clusterIP: None) for pod DNS resolution. Because the service is named mysql, pods are accessible via pod-name.mysql.
# A service name mysql-read to connect to for database reads. This service uses the default ServiceType of ClusterIP which assigns an internal IP address that load balances request to all the pods labeled with app: mysql.

# write: mysql-0.mysql <-- headless
# read: mysql-read <-- normal

cat <<EOF > mysql-storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: general
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
EOF

cat <<'EOF' > mysql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql
  replicas: 3
  template:
    metadata:
      labels:
        app: mysql
    spec:
      initContainers:
      - name: init-mysql
        image: mysql:5.7.35
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Generate mysql server-id from pod ordinal index.
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          echo [mysqld] > /mnt/conf.d/server-id.cnf
          # Add an offset to avoid reserved server-id=0 value.
          echo server-id=$((100 + $ordinal)) >> /mnt/conf.d/server-id.cnf
          # Copy appropriate conf.d files from config-map to emptyDir.
          if [[ $ordinal -eq 0 ]]; then
            cp /mnt/config-map/master.cnf /mnt/conf.d/
          else
            cp /mnt/config-map/slave.cnf /mnt/conf.d/
          fi
        volumeMounts:
        - name: conf
          mountPath: /mnt/conf.d
        - name: config-map
          mountPath: /mnt/config-map
      - name: clone-mysql
        image: gcr.io/google-samples/xtrabackup:1.0
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Skip the clone if data already exists.
          [[ -d /var/lib/mysql/mysql ]] && exit 0
          # Skip the clone on primary (ordinal index 0).
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          [[ $ordinal -eq 0 ]] && exit 0
          # Clone data from previous peer.
          ncat --recv-only mysql-$(($ordinal-1)).mysql 3307 | xbstream -x -C /var/lib/mysql
          # Prepare the backup.
          xtrabackup --prepare --target-dir=/var/lib/mysql
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ALLOW_EMPTY_PASSWORD
          value: "1"
        ports:
        - name: mysql
          containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping"]
          initialDelaySeconds: 30
          timeoutSeconds: 5
        readinessProbe:
          exec:
            # Check we can execute queries over TCP (skip-networking is off).
            command: ["mysql", "-h", "127.0.0.1", "-e", "SELECT 1"]
          initialDelaySeconds: 5
          timeoutSeconds: 1
      - name: xtrabackup
        image: gcr.io/google-samples/xtrabackup:1.0
        ports:
        - name: xtrabackup
          containerPort: 3307
        command:
        - bash
        - "-c"
        - |
          set -ex
          cd /var/lib/mysql
          # Determine binlog position of cloned data, if any.
          if [[ -f xtrabackup_slave_info ]]; then
            # XtraBackup already generated a partial "CHANGE MASTER TO" query
            # because we're cloning from an existing replica.
            mv xtrabackup_slave_info change_master_to.sql.in
            # Ignore xtrabackup_binlog_info in this case (it's useless).
            rm -f xtrabackup_binlog_info
          elif [[ -f xtrabackup_binlog_info ]]; then
            # We're cloning directly from primary. Parse binlog position.
            [[ `cat xtrabackup_binlog_info` =~ ^(.*?)[[:space:]]+(.*?)$ ]] || exit 1
            rm xtrabackup_binlog_info
            echo "CHANGE MASTER TO MASTER_LOG_FILE='${BASH_REMATCH[1]}',\
                  MASTER_LOG_POS=${BASH_REMATCH[2]}" > change_master_to.sql.in
          fi
          # Check if we need to complete a clone by starting replication.
          if [[ -f change_master_to.sql.in ]]; then
            echo "Waiting for mysqld to be ready (accepting connections)"
            until mysql -h 127.0.0.1 -e "SELECT 1"; do sleep 1; done
            echo "Initializing replication from clone position"
            # In case of container restart, attempt this at-most-once.
            mv change_master_to.sql.in change_master_to.sql.orig
            mysql -h 127.0.0.1 <<EOF
          $(<change_master_to.sql.orig),
            MASTER_HOST='mysql-0.mysql',
            MASTER_USER='root',
            MASTER_PASSWORD='',
            MASTER_CONNECT_RETRY=10;
          START SLAVE;
          EOF
          fi
          # Start a server to send backups when requested by peers.
          exec ncat --listen --keep-open --send-only --max-conns=1 3307 -c \
            "xtrabackup --backup --slave-info --stream=xbstream --host=127.0.0.1 --user=root"
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 100m
            memory: 50Mi
      volumes:
      - name: conf
        emptyDir: {}
      - name: config-map
        configMap:
          name: mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 2Gi
      storageClassName: general
EOF

# init-containers: Run to completion before any containers in the Pod spec
#     init-mysql: Assigns a unique MySQL server ID starting from 100 for the first pod and incrementing by one, as well as copying the appropriate configuration file from the config-map. Note the config-map is mounted via the VolumeMounts section. The ID and appropriate configuration file are persisted on the conf volume.
#     clone-mysql: For pods after the primary, clone the database files from the preceding pod. The xtrabackup tool performs the file cloning and persists the data on the data volume.

# spec.containers: Two containers in the pod
#     mysql: Runs the MySQL daemon and mounts the configuration in the conf volume and the data in the data volume
#     xtrabackup: A sidecar container that provides additional functionality to the mysql container. It starts a server to allow data cloning and begins replication on replicas using the cloned data files.

# spec.volumes: conf and config-map volumes are stored on the node's local disk. They are easily re-generated if a failure occurs and don't require PVs.

# volumeClaimTemplates: A template for each pod to create a PVC with. ReadWriteOnce accessMode allows the PV to be mounted by only one node at a time in read/write mode. The storageClassName references the AWS EBS gp2 storage class named general that you created earlier.
k create -f mysql-statefulset.yaml
k get pods -l app=mysql --watch
```

#### Working with the Stateful Application

```bash
kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never --\
  /usr/bin/mysql -h mysql-0.mysql -e "CREATE DATABASE mydb; CREATE TABLE mydb.notes (note VARCHAR(250)); INSERT INTO mydb.notes VALUES ('k8s Cloud Academy Lab');"

kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never --\
  /usr/bin/mysql -h mysql-read -e "SELECT * FROM mydb.notes"

kubectl run mysql-client-loop --image=mysql:5.7 -it --rm --restart=Never --\
  bash -ic "while sleep 1; do /usr/bin/mysql -h mysql-read -e 'SELECT @@server_id'; done"

# simulate taking the node running the mysql-2 pod out of service for maintenance
node=$(kubectl get pods --field-selector metadata.name=mysql-2 -o=jsonpath='{.items[0].spec.nodeName}')
kubectl drain $node --force --delete-local-data --ignore-daemonsets
# pods will be rescheduled into a different node

# undo drain
kubectl uncordon $node

# simulate node failure and see if pod is rescheduled
kubectl delete pod mysql-2
kubectl get pod mysql-2 -o wide --watch

# scale number of replicas to 5
kubectl scale --replicas=5 statefulset mysql
kubectl get pods -l app=mysql --watch

# verify mysql server ids
kubectl run mysql-client-loop --image=mysql:5.7 -it --rm --restart=Never --\
  bash -ic "while sleep 1; do /usr/bin/mysql -h mysql-read -e 'SELECT @@server_id'; done"

# change service type
echo "  type: LoadBalancer" >> mysql-services.yaml
k apply -f mysql-services.yaml

load_balancer=$(kubectl get services mysql-read -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')
kubectl run mysql-client-loop --image=mysql:5.7 -i -t --rm --restart=Never --\
  bash -ic "while sleep 1; do /usr/bin/mysql -h $load_balancer -e 'SELECT @@server_id'; done"
```

#### Monitoring Your Kubernetes Cluster Using Kubernetes Dashboard

```bash
cat << EOF > dashboard-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
EOF

k create -f dashboard-admin.yaml

kubectl -n kubernetes-dashboard create token dashboard-admin
# The --address option allows connections from anywhere. This is only acceptable for demonstration purposes.
kubectl port-forward -n kubernetes-dashboard --address 0.0.0.0 service/kubernetes-dashboard 8001:443
```

### Introduction to Helm

```bash
helm search hub <keyword>
helm search repo <keyword> # research from local repos
helm pull [chart URL | repo/chartname]
helm install <name> <chart>
helm history <release>
helm upgrade <release> <chart>
helm rollback <release> <revisioin>
helm uninstall <release>

helm repo add <name> <url>
helm repo list
helm repo remove <name>
helm repo update
helm repo index <dir>

helm status <release>
helm list
helm history <release>
helm get manifest <release>

helm create <name>
helm template <name> <chart>
helm package <chart>
helm lint <chart>
```

#### Creating, Packaging, and Installing Custom Charts

```bash
helm create <chart-name>
# in template
{{ .Value.service.port }}
# cli
helm upgrade ca-demo1 ./cloudacademy-app --set=service.port=9090

helm package ./ca-app
# -> cloudacademyapp-0.1.3.tgz
helm install ca-demo1 cloudacademyapp-0.1.3.tgz
helm install ca-demo1 cloudacademyapp-0.1.3.tgz --set=app.color=red --dry-run
helm repo index .
# -> index.yaml

helm repo add local http://127.0.0.1:8080
helm repo upate
helm search repo cloudacademy
helm install ca-demo1 local/cloudacademyapp
```

#### Understanding Template Syntax and Features

```bash
helm lint ./webserver
helm install cademo1 ./webserver --dry-run
helm install cademo1 ./webserver
```

#### DEMO

```bash
# installing bitnami wordpress helm chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo wordpress

# helm install wordpress bitnami/wordpress \
#   --set serviceType=NodePort \
#   --set global.storageClass=wordpress

# helm list
helm pull bitnami/wordpress --untar
```

```bash
helm create cloudacademy-webapp
#...
#...
helm lint .
helm template .
cd ..
helm package cloudacademy-webapp

k create ns cloudacademy
k config set-context --current --namespace cloudacademy
helm install ca-demo1 cloudacademy-webapp-0.1.0.tgz

k run --image=busybox bbox1 --restart=Never -it --rm -- /bin/sh -c "wget -qO- http://10.103.203.205"

helm upgrade ca-demo1 cloudacademy-webapp-0.1.0.tgz --set nginx.conf.message='Helm Rocks!'

k rollout history deploy ca-demo1-cloudacademy-webapp
helm history ca-demo1

helm repo index .
# cat index.yaml
# git checkout --orphan gh-pages
# git add index.yaml cloudacademy-webapp-0.1.0.tgz
# git commit -m "..."
# git push -u origin gh-pages

# curl -i https://<username>.github.io/helm-repo/index.yaml
# helm repo add <username> https://<username>.github.io/helm-repo
# helm repo update
# helm search repo <username>
# helm install ca-demo1 <username>/cloudacademy-webapp --set nginx.conf.message='Hello World!'
```

### Performing a Kubernetes Deployment using ConfigMaps and Helm

```bash

```

### Exposing Applications using Kubernetes Ingress Rules

A Kubernetes Ingress object is a resource for managing external access to services within a cluster. Typically Ingress resources are used to expose HTTP(S) routes. An Ingress resource can provide any of the following:

- Load balancing
- SSL termination
- HTTP Virtual Hosting (routing based on the domain name in a request)
- HTTP URL path-based routing

Nginx ingress controller

- in AWS, create network load balancer
- in bare metal, node port

```bash
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue-app
spec:
  selector:
    matchLabels:
      app: blue-app
  replicas: 2
  template:
    metadata:
      labels:
        app: blue-app
    spec:
      containers:
      - name: blue-app
        image: public.ecr.aws/cloudacademy-labs/cloudacademy/labs/k8s-ingress-app:f9a36c8
        env:
        - name: COLOR
          value: '#A7C7E7'
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: blue-app
spec:
  selector:
    app: blue-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
EOF

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: red-app
spec:
  selector:
    matchLabels:
      app: red-app
  replicas: 2
  template:
    metadata:
      labels:
        app: red-app
    spec:
      containers:
      - name: red-app
        image: public.ecr.aws/cloudacademy-labs/cloudacademy/labs/k8s-ingress-app:f9a36c8
        env:
        - name: COLOR
          value: '#FAA0A0'
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: red-app
spec:
  selector:
    app: red-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
EOF

cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: lab-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /blue
        pathType: Prefix
        backend:
          service:
            name: blue-app
            port:
              number: 80
      - path: /red
        pathType: Prefix
        backend:
          service:
            name: red-app
            port:
              number: 80
EOF

kubectl logs -l app.kubernetes.io/name=ingress-nginx --namespace ingress-nginx

# Routing requests by hostname is often called Virtual Hosting or Name Based Routing.
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: lab-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: blue.example.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: blue-app
            port:
              number: 80
  - host: red.example.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: red-app
            port:
              number: 80
EOF

load_balancer_dns=$(kubectl -n ingress-nginx get service ingress-nginx-controller -o jsonpath={.status.loadBalancer.ingress[0].hostname})
# kubectl get ing lab-ingress -o jsonpath={.status.loadBalancer.ingress[0].hostname}
curl --header "Host: blue.example.com" http://$load_balancer_dns
curl --header "Host: red.example.com" http://$load_balancer_dns
```

### Using Kubernetes Primitives to Implement Common Deployment Strategies

- RollingUpdate / Recreate
- Canary deployments - A small subset of traffic is sent to the new version to build confidence in it before fully deploying the new version
- Blue/Green deployments - All traffic is cut over from the existing version, referred to as the "blue" environment, to the new version, referred to as the "green" environment. Traffic is not simultaneously served by old and new versions with the blue/green strategy, in contrast to rolling deployments and canary deployments.

```bash
# Create namespace
kubectl create namespace strategies
# Set namespace as the default for the current context
kubectl config set-context $(kubectl config current-context) --namespace=strategies

#### BLUE / GREEN START
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
    version: old
  name: app
spec:
  replicas: 10
  selector:
    matchLabels:
      app: web
      version: old
  strategy:
    type: RollingUpdate # Default value is RollingUpdate, Recreate also supported
  template:
    metadata:
      labels:
        app: web
        version: old
    spec:
      containers:
      - image: nginx:1.21.3-alpine
        name: nginx
        ports:
        - containerPort: 80
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 80
            scheme: HTTP
          periodSeconds: 5
          successThreshold: 2
          timeoutSeconds: 10
EOF

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: web
  name: app
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: web
  type: LoadBalancer
EOF

## edit svc selector
selector:
  app: web
  version: old

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
    version: new
  name: app-new
spec:
  replicas: 10
  selector:
    matchLabels:
      app: web
      version: new
  template:
    metadata:
      labels:
        app: web
        version: new
    spec:
      containers:
      - image: httpd:2.4.49-alpine3.14
        name: httpd
        ports:
        - containerPort: 80
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 80
            scheme: HTTP
          periodSeconds: 5
          successThreshold: 2
          timeoutSeconds: 10
EOF

# edit svc selector
selector:
  app: web
  version: new

k delete deploy app

# edit svc selector
selector:
  app: web

#### BLUE / GREEN END
#### CANARY START
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
    version: canary
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
      version: canary
  template:
    metadata:
      labels:
        app: web
        version: canary
    spec:
      containers:
      - image: caddy:2.4.5-alpine
        name: caddy
        ports:
        - containerPort: 80
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 80
            scheme: HTTP
          periodSeconds: 5
          successThreshold: 2
          timeoutSeconds: 10
EOF

## test if canary works
while true; do curl a26c0984929744948bbd12e796f225e2-1477021901.us-west-2.elb.amazonaws.com | grep works; sleep 1; done;

## remove canary deployment
k delete deploy app-canary

## replace existing deployment eg) change image name
## updated version will be deployed

#### CANARY END
```

### Using Kubernetes Custom Resource Definition (CRDs)

- crd also appears by `k api-resources`

```bash
k grt crd
k get crd applications.argoproj.io -o yaml

apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  creationTimestamp: "2023-09-07T04:25:39Z"
  generation: 1
  labels:
    app.kubernetes.io/name: applications.argoproj.io
    app.kubernetes.io/part-of: argocd
  name: applications.argoproj.io
  resourceVersion: "118002"
  uid: d1dbb8a4-ac39-4cdd-abc8-006b6b49d64b
spec:
  conversion:
    strategy: None
  group: argoproj.io
  names:
    kind: Application
    listKind: ApplicationList
    plural: applications
    shortNames:
    - app
    - apps
    singular: application
  scope: Namespaced
  ...
    schema:
      openAPIV3Schema:
        description: Application is a definition of Application resource.
        properties:
          apiVersion:


kubectl get applications -A
k describe app guestbook

kubectl edit app guestbook
```

### Understand Kubernetes API Access Control Mechanisms

Kubernetes provides three access control layers to secure the Kubernetes API server:

- Authentication: Requests sent to the API server are authenticated to prove the identity of the requester, be it a normal user or a service account, and are rejected otherwise.
- Authorization: The action specified in the request must be in the list of actions the authenticated user is allowed to perform or it is rejected.
- Admission Control: Authorized requests must then pass through all of the admission controllers configured in the cluster (excluding read-only requests) before any action is performed.

#### Understanding Kubernetes Authentication

```bash
$ k get pods --v=6
I0908 00:09:04.835669    1894 loader.go:374] Config loaded from file:  /home/ubuntu/.kube/config
I0908 00:09:04.846585    1894 round_trippers.go:553] GET https://10.0.0.100:6443/apis/metrics.k8s.io/v1beta1?timeout=32s 503 Service Unavailable in 9 milliseconds
...
No resources found in default namespace.

$ cat /home/ubuntu/.kube/config
apiVersion: v1
kind: Config
clusters:
  - cluster:
    name: kubernetes
contexts:
  - context:
      cluster: kubernetes
      user: kubernetes-admin
    name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
users:
  - name: kubernetes-admin
    user:
      client-certificate-data:
      client-key-data:
    ...

k config get-contexts
k config use-context <name>


kubectl run nginx --image=nginx
k describe po nginx
# ...
# Service Account: default
# ...
# Volumes:
#   kube-api-access-dz6gl:
#     Type:                    Projected (a volume that contains injected data from multiple sources)
#     TokenExpirationSeconds:  3607
#     ConfigMapName:           kube-root-ca.crt
# ...
kubectl exec nginx -- cat /var/run/secrets/kubernetes.io/serviceaccount/token && echo
# service account use token for authentication
# - A token acquired from kube-apiserver that will expire after 1 hour by default or when the pod is deleted. The token is bound to the pod and allows communication with the kube-apiserver.
# - A ConfigMap containing a CA bundle used for verifying connections to the kube-apiserver.
```

#### Understanding Kubernetes Authorization

The default authorization mechanism in Kubernetes is role-based access control (RBAC). In RBAC, subjects (users, groups, ServiceAccounts) are bound to roles and the roles describe what actions the subject is allowed to perform. There are two kinds of roles in Kubernetes RBAC:

- Role: A namespaced resource specifying allowed actions
- ClusterRole: A non-namespaced resource specifying allowed actions

There are two resources available for binding roles to subjects:

- RoleBinding: Bind a Role or ClusterRole to a subject(s) in a Namespace
- ClusterRoleBinding: Bind a ClusterRole to a subject(s) cluster-wide

```bash
k get roles -A
kubectl get -n kube-system role kube-proxy -o yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: "2023-03-25T06:18:57Z"
  name: kube-proxy
  namespace: kube-system
  resourceVersion: "230"
  uid: 81378117-1f20-4343-b506-7430c480945b
rules:
- apiGroups:
  - "" # core api group
  resourceNames:
  - kube-proxy
  resources:
  - configmaps
  verbs:
  - get

k get clusterroles
k get clusterrole cluster-admin -o yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: "2023-03-25T06:18:54Z"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
  resourceVersion: "73"
  uid: 6f512a08-f86a-42f1-9094-3e0e7efdf934
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'

k get clusterrolebinding cluster-admin -o yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: "2023-03-25T06:18:55Z"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
  resourceVersion: "135"
  uid: 6ba06c24-05d0-4891-8c81-4f756622f231
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:masters

# check if allowed
k auth can-i --help
k auth can-i list nodes
k auth can-i list nodes --as=Tracy
```

#### Understanding Kubernetes Admission Control

- a request should pass all admission controller (eg ResourceQuote)
- some adminition controller can modify request (eg LimitRanger modify cpu/memory if not set)
- by default 17 admission controllers

```bash
kubectl exec -n kube-system kube-apiserver-ip-10-0-0-100.us-west-2.compute.internal \
  -- kube-apiserver -h | grep "enable-admission-plugins strings"

ssh 10.0.0.100 -oStrictHostKeyChecking=no
ps -ef | grep kube-apiserver | grep enable-admission-plugins
# ... --enable-admission-plugins=NodeRestriction ...
```

### Getting Started with Docker on Linux for AWS

```bash
sudo yum -y install docker
sudo systemctl start docker
sudo docker info

grep docker /etc/group
# docker:x:993:
# sudo groupadd docker # if docker group not existing
sudo gpasswd -a $USER docker
# Adding user ec2-user to group docker

sudo yum -y install git
git clone https://github.com/cloudacademy/flask-content-advisor.git

####
# Python v3 base layer
FROM python:3
# Set the working directory in the image's file system
WORKDIR /usr/src/app
# Copy everything in the host working directory to the container's directory
COPY . .
# Install code dependencies in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
# Indicate that the server will be listening on port 5000
EXPOSE 5000
# Set the default command to run the app
CMD [ "python", "src/app.py" ]
####

docker build -t flask-content-advisor:latest .
docker run --name advisor -p 80:5000 flask-content-advisor
```

## CKAD Practice Exam

### Core Concepts

```bash

```

### Configuration

```bash

```

### Multi-Container Pods

```bash

```

### Observability

```bash

```

### Pod Design

```bash

```

### Services & Networking

```bash

```

### State Persistent

```bash

```

## Challenges

### Kubernetes Certificate Challenge

```bash

```

### Certified Kubernetes Application Developer (CKAD) Challenge

```bash

```

### Cert Prep: Certified Kubernetes Application Developer (CKAD)

```bash

```
