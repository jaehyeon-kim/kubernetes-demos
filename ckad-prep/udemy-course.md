# Introduction

- Certified Kubernetes Application Developer: https://www.cncf.io/certification/ckad/
- Candidate Handbook: https://www.cncf.io/certification/candidate-handbook
- Exam Tips: https://docs.linuxfoundation.org/tc-docs/certification/tips-cka-and-ckad

Keep the code - `20KLOUD` handy while registering for the CKA or CKAD exams at Linux Foundation to get a 20% discount.

- Cheat Sheet - https://kubernetes.io/docs/reference/kubectl/cheatsheet/

<!-- https://killercoda.com/ -->

# CORE CONCEPTS

## Pods

```bash
kubectl get pods
kubectl run redis --image=redis123

kubectl run redis --image=redis123 --dry-run=client -o yaml > redis.yaml
kubectl create -f redis.yaml
kubectl apply -f redis.yaml

kubectl describe pod redis
kubectl get pods -o wide
kubectl set image pod/redis redis=redis
kubectl delete pod redis
```

### Note on Editing Existing Pods

In any of the practical quizzes if you are asked to edit an existing POD, please note the following:

1. If you are given a pod definition file, edit that file and use it to create a new pod.
2. If you are not given a pod definition file,

- you may extract the definition to a file using the below command:
  - `kubectl get pod <pod-name> -o yaml > pod-definition.yaml``
- Then edit the file to make the necessary changes, delete and re-create the pod.

3. Use the kubectl edit pod <pod-name> command to edit pod properties.

## ReplicaSets

```bash
kubectl create -f replicaset-definition.yml
kubectl get replicaset
kubectl delete replicaset myapp-replicaset

kubectl explain replicaset

# even if images are changed, existing pods won't be updated
# existing pods should be deleted or recreate rs

kubectl replace -f replicaset-definition.yml
kubectl scale --replicas=6 -f replicaset-definition.yml
kubectl scale --replicas=6 -f replicaset myapp-replicaset # template file won't be updated
kubectl edit replicaset myapp-replicaset

## ReplicationController
selector:
  key: value

## ReplicaSet <-- more selector support
selector:
  matchLabels:
    key: value

```

## Deployments

```bash
kubectl create -f httpd-frontend-deployment.yml
kubectl create deployment httpd-frontend --image=httpd:2.4-alpine --replicas=3
kubeclt get deployments
kubectl get replicasets
kubectl get pods

kubectl get all
```

### TIP - kubectl output format

The default output format for all kubectl commands is the human-readable plain-text format.

The -o flag allows us to output the details in several different formats.

`kubectl [command] [TYPE] [NAME] -o <output_format>`

- `-o json` Output a JSON formatted API object.
- `-o name` Print only the resource name and nothing else.
- `-o wide` Output in the plain-text format with any additional information.
- `-o yaml` Output a YAML formatted API object.

## Namespaces

- Namespace
- ResourceQuota

```bash
kubectl create ns dev

kubectl get pod --namespace=dev #(or -n=dev)

kubectl config set-context $(kubectl congig current-context) --namespace=dev
kubectl get pod

kubectl get pods --all-namespaces

## service referencing
# service can be referred by name in the same namespace - db-service
# service can be referred by full name in a different namespace - db-service.dev.svc.cluster.local

apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: dev
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    requests.nvidia.com/gpu: 4
```

## Serivce

- ClusterIP: not exposed outside
- NodePort: exposed on port of node
- LoadBalancer: distribute traffic into different services

```
apiVersion: v1
kind: Service
metadata:
  name: redis-db
spec:
  type: ClusterIP
  ports:
  - targetPort: 6379
    port: 6379
  selector:
    app: myapp
    name: redis-pod

apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  ports:
  - targetPort: 80 # same to port if not set
    port: 80
    nodePort: 30008 # (30000-32767)
  selector:
    app: myapp
    name: front-end
```

### TIP - imperative commands

While you would be working mostly the declarative way - using definition files, imperative commands can help in getting one-time tasks done quickly, as well as generate a definition template easily. This would help save a considerable amount of time during your exams.

Before we begin, familiarize yourself with the two options that can come in handy while working with the below commands:

- `--dry-run`: By default, as soon as the command is run, the resource will be created. If you simply want to test your command, use the `--dry-run=client` option. This will not create the resource. Instead, tell you whether the resource can be created and if your command is right.
- `-o yaml`: This will output the resource definition in YAML format on the screen.

Use the above two in combination along with Linux output redirection to generate a resource definition file quickly, that you can then modify and create resources as required, instead of creating the files from scratch.

`kubectl run nginx --image=nginx --dry-run=client -o yaml > nginx-pod.yaml`

More examples

- Create an NGINX Pod
  - `kubectl run nginx --image=nginx`
- Generate POD Manifest YAML file (-o yaml). Don't create it(--dry-run)
  - `kubectl run nginx --image=nginx --dry-run=client -o yaml`
- Create a deployment
  - `kubectl create deployment nginx --image=nginx`
- Generate Deployment YAML file (-o yaml). Don't create it(--dry-run)
  - `kubectl create deployment nginx --image=nginx --dry-run -o yaml`
- Generate Deployment with 4 Replicas
  - `kubectl create deployment nginx --image=nginx --replicas=4`
- You can also scale deployment using the kubectl scale command.
  - `kubectl scale deployment nginx --replicas=4`
- Another way to do this is to save the YAML definition to a file and modify
  - `kubectl create deployment nginx --image=nginx--dry-run=client -o yaml > nginx-deployment.yaml`
  - You can then update the YAML file with the replicas or any other field before creating the deployment.

Service

- Create a Service named redis-service of type ClusterIP to expose pod redis on port 6379

  - `kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml` (This will automatically use the pod's labels as selectors)
  - Or `kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml` (This will not use the pods' labels as selectors; instead it will assume selectors as app=redis. You cannot pass in selectors as an option. So it does not work well if your pod has a different label set. So generate the file and modify the selectors before creating the service)

- Create a Service named nginx of type NodePort to expose pod nginx's port 80 on port 30080 on the nodes:
  - `kubectl expose pod nginx --port=80 --name nginx-service --type=NodePort --dry-run=client -o yaml` (This will automatically use the pod's labels as selectors, but you cannot specify the node port. You have to generate a definition file and then add the node port in manually before creating the service with the pod.)
  - Or `kubectl create service nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml` (This will not use the pods' labels as selectors)

Both the above commands have their own challenges. While one of it cannot accept a selector, the other cannot accept a node port. I would recommend going with the `kubectl expose` command. If you need to specify a node port, generate a definition file using the same command and manually input the nodeport before creating the service.

Reference:
https://kubernetes.io/docs/reference/kubectl/conventions/

```bash
1. kubectl run nginx --image=nginx
2. kubectl run redis --image=redis:alpine --labels="tier=db"
3.
kubectl run redis --image=redis:alpine
kubectl expose pod redis --port=6379 --name redis-service # automatically detect labels and use it
4. kubectl create deployment webapp --image=kodekloud/webapp-color --replicas=3
5. kubectl run custom-nginx --image=nginx --port=8080
6. kubectl create ns dev-ns
7. kubectl create deploy redis-deploy --image=redis --replicas=2 -n dev-ns
8.
kubectl run httpd --image httpd:alpine
kubectl expose pod httpd --port 80

kubectl run httpd --image httpd:alpine --port 80 --expose=true
```

# CONFIGURATION

## Command and Arguments

```bash
FROM ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]

docker run ubuntu-sleeper # default 5
docker run ubuntu-sleeper 10

docker run --name ubuntu-sleeper --entrypoint sleep2 ubuntu-sleeper 10

apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleeper-pod
spec:
  containers:
    - name: ubuntu-sleeper
      image: ubuntu-sleeper
      command: ["sleep2"]
      args: ["10"]

kubectl run webapp-green --image=kodekloud/webapp-color -- --color=green
```

## Note on editing Pod and Deployment

**Pod**

Remember, you CANNOT edit specifications of an existing POD other than the below.

- spec.containers[*].image
- spec.initContainers[*].image
- spec.activeDeadlineSeconds
- spec.tolerations

For example you cannot edit the environment variables, service accounts, resource limits (all of which we will discuss later) of a running pod. But if you really want to, you have a number of options:

1. Run the `kubectl edit pod <pod name>` command. This will open the pod specification in an editor (vi editor). Then edit the required properties. When you try to save it, you will be denied. This is because you are attempting to edit a field on the pod that is not editable.
   - A copy of the file with your changes is saved in a temporary location as shown above. You can then delete the existing pod by running the command: `kubectl delete pod webapp`
   - Then create a new pod with your changes using the temporary file `kubectl create -f /tmp/kubectl-edit-ccvrq.yaml`.
2. Or `kubectl replace --force -f /tmp/kubectl-edit-ccvrq.yaml`
3. The second option is to extract the pod definition in YAML format to a file using the command: `kubectl get pod webapp -o yaml > my-new-pod.yaml`. Then make the changes to the exported file using an editor (vi editor)
   - Then delete the existing pod by running the command: `kubectl delete pod webapp`
   - Then create a new pod with the edited file - `kubectl create -f my-new-pod.yaml`

**Deployment**

With Deployments you can easily edit any field/property of the POD template. Since the pod template is a child of the deployment specification, with every change the deployment will automatically delete and create a new pod with the new changes. So if you are asked to edit a property of a POD part of a deployment you may do that simply by running the command: `kubectl edit deployment my-deployment`.

Override command or argument

- `kubectl run webapp-green --image kodekloud/webapp-color -- --color green`
- `kubectl run webapp-green --image kodekloud/webapp-color --command -- python app2.py --color green`

## Environment Variables and ConfigMaps

```bash
env:
  - name: APP_COLOR
    value: pink

envFrom:
  - configMapRef:
      name: app-config

env:
  - name: APP_COLOR
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: APP_COLOR

volumes:
- name: app-config-volume
  configMap:
    name: app-config

kubectl create configmap app-config --from-literal=APP_COLOR=blue --from-literal=APP_MOD=prod
kubectl create configmap app-config --from-file=path-to-file

apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  APP_COLOR: blue
  APP_MODE: prod
```

## Secrets

```bash
kubectl create secret generic app-secret --from-literal=password=foo

kubectl create secret generic app-secret --from-file=<path-to-file>

echo -n foo | base64
echo -n Zm9v | base64 --decode

apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  password: Zm9v

kubectl describe app-secret
kbuectl get secret app-secret -o yaml


envFrom:
- secretRef:
    name: app-secret

env:
- name: APP_COLOR
  valueFrom:
    secretKeyRef:
      name: app-secret
      key: APP_COLOR

volumes:
- name: app-config-volume
  setret:
    secretName: app-config


kubectl replace --force -f <path-to-file>
kubectl get secrets -A -o json | kubectl replace -f -
```

- secrets are not encrypted but only encoded
  - don't store in source control
- secrets are not encrypted in etcd
  - https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
- anyone able to creates pods/deployment in the same namespace can access the screts
  - configure least-priviledge access to secrets - RBAC
- consider 3rd-party secrets store providers
  - aws provider, azure provider, valult provider ...

### Encrypting secret data at rest

https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

## Security Contexts

docker run --user=1000 ubuntu sleep 3600
docker run --cap-add MAC_ADMIN ubuntu sleep 3600
docker run --cap-drop KILL ubuntu sleep 3600

```bash
apiVersion: v1
kind: Pod
metadata:
  name: web-ap
spec:
  securityContext:
    runAsUser: 1000 <-- either in pod or container level
  containers:
  - name: ubuntu
    image: ubuntu
    command: ["sleep", "3600"]
    securityContext:
      runAsUser: 1000
      capabilities: <-- only supported in container leel
        add: ["MAC_ADMIN"]
        drop: ["KILL"]


kubectl exec ubuntu-sleeper -- whoami
```

## Service Accounts

```bash
metadata:
  name: web-ap
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    command: ["sleep", "3600"]
    serviceAccountName: my-service-account
    automountServiceAccountToken: false # prevent a default service account token from being mounted

-----------
1.22/1.24 update

kubectl exec -it ubuntu -- cat /var/run/secrets/kubenetes.io/serviceaccount/token
- no expiry date defined

1.22 - TokenRequestAPI is introduced
- audience bound
- time bound
- object bound

apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    command: ["sleep", "3600"]
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-6mtg8
      readOnly: true
  volumes:
  - name: kube-api-access-bmtg8
    projected:
      defaultMode: 420
      sources:
      - serviceAcocuntToken:
          expirationSeconds: 3607
          path: token

1.24 Reduction of secret-based service account token
previously
  kubectl create sa dashboard-sa
  service account --> secret --> token

1.24
  kubectl create sa dashboard-sa
  kubectl create token dashboard-sa <-- time bound

or for non-expiring token

apiVersion: v1
kind: Secret
type: kubernetes.io/service-acocunt-token
metadata:
  name: mysecretname
  annotations:
    kubernetes.io/service-account.name: dashboard-sa

## example RoleBinding
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: dashboard-sa # Name is case sensitive
  namespace: default
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

## Resource Requirements

```bash
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "1Gi"
        cpu: 1
      limits:
        memory: "2Gi" <- terminated by OOM error
        cpu: 2 <- throttle if exceed

no request, no limit - single pod can consume all
no request, limit - request = limit
request, limit - guaranteed number of resources bound by limits, a pod cannot consume more than its limit in spite of spare capacity in nodes
request, no limit - when available, consumer as many resources as available, can be ideal in many situations

# How to ensure limits? -> LimitRange, applicable to namespace level

apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-resource-constraint
spec:
  limits:
  - default:
      cpu: 500m #<- limit
    defaultRequest:
      cpu: 500m #<- request
    max:
      cpu: "1" #<- limit
    min:
      cpu: 100m #<- request
    type: Container

# How to restrict total amount of resources? -> Request Quotas, namespace level

apiVersion: v1
kind: RequestQuota
metadata:
  name: my-resource-quota
spec:
  hard:
    requests.cpu: 4
    requests.memory: 4Gi
    limits.cpu: 10
    limits.memory: 10Gi
```

## Taint and Tolerations

```bash
# Node affinity is a property of Pods that attracts them to a set of nodes (either as a preference or a hard requirement).
# Taints are the opposite -- they allow a node to repel a set of pods.

kubectl taint nodes <node-name> key=value:<taint-effect>
# taint-effect: NoSchedule | PreferNoSchedule | NoExecute
# kubectl taint nodes node1 app=blue:NoSchedule

apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: nginx-container
    image: nginx
  tolerations:
  - key: "app"
    operator: "equal"
    value: "blue"
    effect: "NoSchedule"

# pods not scheduled in the master node
kubectl describe node kubemaster | grep Taint
# Taints: node-role.kubernetes.io/master:NoSchedule

```

## Node Selectors / Node Affinity

```bash
kubectl get node node01 --show-labels

# node selectors - only equality, what about OR / NOT conditions?
kubectl label nodes <node-name> <label-key>:<label-value>
kubectl label nodes node01 size=Large

apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: nginx-container
    image: nginx
  nodeSelector:
    size: Large
```

```bash
# node affinity
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: nginx-container
    image: nginx
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: size
            operator: In
            values:
            - Large
            - Medium

...
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: size
            operator: NotIn
            values:
            - Small

...
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: size
            operator: Exists

# node affinity types
# requiredDuringSchedulingIgnoredDuringExecution
# preferredDuringSchedulingIgnoredDuringExecution

# planned - requiredDuringSchedulingRequiredDuringExecution
```

# Multi Containers

## Multi-container Pods

```bash
# ambassdor - main app connect to db via localhost + agent proxies to the right db instance (dev, prod ...)
# adapter - web server + log agent <-- standardize log formats of different apps
# sidecar - web server + log agent

# https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
spec:
  containers:
  - name: nginx-container
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: debian-container
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/sh"]
    args: ["-c", "echo Hello from the debian container > /pod-data/index.html"]
  volumes:
  - name: shared-data
    emptyDir: {}


kubectl -n elastic-stack logs kibana

kubectl -n elastic-stack logs app
kubectl exec app -n elastic-stack -- cat /log/app.log
```

## Init containers

```bash
# https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

# multi-containers - all containers should run
# for one-time execution, we can use init containers
# main container runs after init containers
# if multiple init containers, they run in sequence

apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox
    command: ['sh', '-c', 'git clone <some-repository-that-will-be-used-by-application> ;']
```

# Observability

## Readiness and liveness probes

- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```bash
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp
  labels:
    name: simple-webapp
spec:
  containers:
  - name: simple-webapp
    image: simple-webapp
    ports:
    - containerPort: 8080
    readinessProbe: # livenessProbe:
      httpGet:
        path: /api/ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 8 # default 3

    readinessProbe: # livenessProbe:
      tcpSocket:
        port: 3306

    readinessProbe: # livenessProbe:
      exec:
        command:
          - cat
          - /app/is_ready

kubectl get po -o yaml > webapps.yaml
kubectl delete po --all
```

## Container logging

```bash
docker run -d <image>
docker logs -f <container-id>

kubectl logs -f <pod-name>
kubectl logs -f <pod-name> <container-name> # if multiple containers
```

## Monitor and debug applications

- metrics server: in-memory only, no data persisted

```bash
git clone https://github.com/kodekloudhub/kubernetes-metrics-server.git
cd kubernetes-metrics-server
kubectl create -f .

kubectl top node
kubectl top pod
```

# POD design

## Labels, selectors and annotations

```bash
kubectl get pods --selector app=App1
kubectl get pods --selector app=App1,teir=web
# labels to select/filter resources
# annotations for other info

kubectl get po --show-labels
kubectl get po --selector env=dev --no-headers | wc -l
```

## Rolling updates & rollbacks in deployments / Updating a deployment

- recreate, rolling update ... default: rolling update

```bash
## CREATE
kubectl create -f deployment-definition.yml
## GET
kubectl get deployments
## UPDATE
kubectl apply -f deployment-definition.yml
kubectl set image deploy/myapp-deployment nginx-container=nginx:1.9.1
## STATUS
kubectl rollout status deploy/myapp-deployment
kubectl rollout history deploy/myapp-deployment
## ROLEBACK
kubectl rollout undo deploy/myapp-deployment

## example
# revision 1
kubectl create deployment nginx --image=nginx:1.16
kubectl rollout status deployment nginx
kubectl rollout history deployment nginx
kubectl rollout history deployment nginx --revision=1 # get specific revision
# revision 2
kubectl set image deployment nginx nginx=nginx:1.17 --record # keep change-cause
kubectl rollout history deployment nginx
# revision 3
kubectl edit deployments. nginx --record
kubectl rollout history deployment nginx
kubectl rollout history deployment nginx --revision=3
# undo changes
kubectl rollout undo deployment nginx --to-revision=2
```

## Jobs, CronJobs

```bash
# pod is not suitable for batch jobs as it assume apps run indefinitely

apiVersion: v1
kind: Pod
metadata:
  name: math-pod
spec:
  containers:
  - name: math-add
    image: ubuntu
    command: ["expr", "3", "+", "2"]
    restartPolicy: Always # Never, Failure

apiVersion: batch/v1
kind: Job
metadata:
  name: math-add-job
spec:
  completions: 3 # schedule until 3 completions
  parallelism: 3 # default 1
  template:
    spec:
      containers:
      - name: math-add
        image: ubuntu
        command: ["expr", "3", "+", "2"]
        restartPolicy: Never

kubectl logs math-add-job-111111
kubectl delete job match-add-job

apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: reporting-cron-job
spec: #<-- for cron job
  schedule: "*/1 * * * *"
  jobTemplate:
    spec: #<-- for job
      completions: 3 # schedule until 3 completions
      parallelism: 3 # default 1
      template:
        spec: #<-- for container
          containers:
          - name: math-add
            image: ubuntu
            command: ["expr", "3", "+", "2"]
            restartPolicy: Never
```

# Services & Networking

## Services

```bash
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: NodePort
  ports:
  - targetPort: 80
    port: 80
    nodePort: 30008
  selector:
    app: myapp
    type: front-end
```

## Ingress networking

- ingress controller eg. https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/
  - deployment, config map, service, service account (with role, role binding...) ...
- ingress resource

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-wear
spec:
  backend:
    service
      name: wear-service
      port:
        number: 80

## path based
# should deploy a service default-http-backend:80 for 404
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-wear-watch
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / # http://<ingress-service>:<ingress-port>/watch --> http://<watch-service>:<port>/watch
spec:
  rules:
  - http:
      paths:
      - path: /wear
        pathType: Prefix
        backend:
          service
            name: wear-service
            port:
              number: 80
  - http:
      paths:
      - path: /watch
        pathType: Prefix
        backend:
          service
            name: watch-service
            port:
              number: 80

## host based
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-wear-watch
spec:
  rules:
  - host: wear.my-site.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: wear-service
            port:
              number: 80
  - host: watch.my-site.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: watch-service
            port:
              number: 80

# https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-ingress-em-
kubectl create ingress <ingress-name> --rule="host/path=service:port
kubectl create ingress ingress-test --rule="wear.my-online-store.com/wear*=wear-service:80

alias k=kubectl
```

## Network Policies

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from: # OR condition
        - podSelector:
            matchLabels:
              role: api-pod
        - namespaceSelector:
            matchLabels:
              name: prod
        - ipBlock:
            cidr: 172.17.0.0/16
            except:
              - 172.17.1.0/24
      - from: # AND condition
        - podSelector:
            matchLabels:
              role: api-pod
          namespaceSelector:
            matchLabels:
              name: prod
      ports:
        - protocol: TCP
          port: 6379
    - to:
        - ipBlock:
            cidr: 172.17.0.0/16
        ports:
          - protocol: TCP
            port: 80
```

# State persistence

## Using PVCs

```bash
apiVersion: v1
kind: Pod
metadata:
  name: random-number-gen
spec:
  containers:
  - image: alpine
    name: alpine
    command: ["/bin/sh", "-c"]
    args: ["shuf -f 0-100 -n 1 >> /opt/number.out;"]
    volumeMounts:
    - mountPath: /opt
      name: data-volume
  volumes:
  - name: data-volume
    hostPath: #<-- can be inconsistent on multi-node cluster
      path: /data
      type: Directory
  - name: cloud-volume
    awsElasticBlockStore:
      volumeID: <volume-id>
      fsType: ext4

## how to manage storage centrally???
## usually admin creates PV and developers use by PVC: PV and PVC are one-to-one
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
  - ReadWriteOnce # ReadOnlyMany, ReadWriteOnce, ReadWriteMany
  capacity:
    storage: 1Gi
  hostPath: # not in prod env
    path: /tmp/dat
  persistentVolumeReclaimPolicy: Retain # <- kept until manually deleted, cannot be used by another claim... Delete, Recycle
  # awsElasticBlockStore:
  #   volumeID: <volume-id>
  #   fsType: ext

# if no selector, bound to any matching PV
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi

apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: myfrontend
    image: nginx
    volumeMounts:
    - mountPath: "/var/www/html"
      name: mypd
  volumes:
  - name: mypd
    persistentVolumeClaim:
      claimName: myClaim
```

## StorageClasses

- static provisioning: need to create EBS volume of the same name before creating PV
- dynamic provisioning: automatically provision and attach to pod with StorageClass - PV is created under the hood

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
allowVolumeExpansion: true
mountOptions:
  - debug
volumeBindingMode: Immediate

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: aws-storage
  capacity:
    storage: 1Gi
  persistentVolumeReclaimPolicy: Retain
```

## StatefulSets, Headless Services, Storage in StatefulSets

- pods are deployed in sequence
- each pod gets a unique name (stable, unique network identifier)

# Updates for Sep 2021 Changes

## Docker images

```bash
FROM Ubuntu
RUN apt-get update && apt-get install python
RUN pip install flask flask-mysql
COPY . /opt/source-code
ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run

docker build -t image-name .
docker push image-name

cat /etc/os-release
```

## AuthN, AuthZ and Admission Control

- controlling access to kube-apiserver
- authN - username/password, username/tokens, certificates, LDAP, service account
- authZ - RBAC, ABAC, Node authz, webhook mode
- encryption in flight via TSL certificate among components (kube proxy, kubelet, etcd ...)
- communication among apps in a cluster via network policy

### AuthN

- users are authenticated by kube-apiserver whether using kubectl or api (https://kube-server-ip:6443)
- static password file, static token file, certificates, identify services (LDAP, kerbros)

```bash
user-details.csv
password123,user1,u001,group1
password123,user2,u002,group1
password123,user3,u003,group2

user-tokens.csv
token-content-1,user1,u001,group1
token-content-2,user2,u002,group1
token-content-3,user3,u003,group2

ExecStart=/usr/local/bin/kube-apiserver ... --basic-auth-file=user-details.csv
curl -v -k https://master-node-ip:6443/api/v1/pods -u "user1:password123"

ExecStart=/usr/local/bin/kube-apiserver ... --user-token-details=user-tokens.csv
curl -v -k https://master-node-ip:6443/api/v1/pods --header "Authorization: Bearer token-content-1"

- not recommended
- consier volume mount while providing the auth file in a kubeadm setup
- setup RBAC for the new users
```

## KubeConfig

- $HOME/.kube/config
- clusters, contexts, users

```bash
cluster | context    | user
DEV     | admin@PROD | admin
PROD    | dev@GOOGLE | dev
GOOGLE  | prod@DEV   | prod


apiVersion: vi
kind: Config
current-context: my-kube-admin@my-kube-playground
clusters:
- name: my-kube-playground
  cluster:
    certificate-authority: etc/kubernetes/pki/ca.crt
    server: https://my-kube-playground:6443
- name: my-kube-playground-2
  cluster:
    certificate-authority-data: <- base64 encoded ca.crt (cat ca.crt | base64)
    server: https://my-kube-playground:6443
contextx:
- name: my-kube-admin@my-kube-playground
  context:
    cluster: my-kube-playgroun
    user: my-kube-admin
    namespace: finance
- name: dev-user@my-kube-playground
  context:
    cluster: my-kube-playgroun
    user: my-kube-admin
users:
- name: my-kube-admin
  user:
    client-certificate: /etc/kubernetes/pki/users/admin.crt
    client-key: etc/kubernetes/pki/users/admin.key

kubectl config view (--kubeconfig=my-custom-config)
kubectl config use-context prod-user@production
```

## Authorization

### API Groups

- curl https://master-node-ip:6443/version
- /metrics, /healthz, /version, /api, /apis, /logs

- core group
- /api -> /v1 -> namespaces, pod, rs, PV, PVC ...
- /apis -> /apps, /extensions, /entworking.k8s.io
-     /apps -> /deployments, /replicasets, /statefulsets
-     /networking.k8s.io -> /v1 -> /networkpolicies

```bash
curl -v -k https://master-node-ip:6443/api/v1/pods --header "Authorization: Bearer token-content-1"

# or
kubectl proxy # auth handled by kubeconfig
# Starting to serve on 127.0.0.1:8001
curl localhost:8001/api/v1/pods -k
```

### Authorization

```bash
- Node - permission given to kubelet
- ABAC - need to restart api server every time?
- RBAC - a role can have permissions, one or more users belong to a group
- Webhook - out-source e.g. to open policy agent (OPA)
- AlwaysAllow, AlwaysDeny

/use/local/bin/kube-apiserver ... --authorization-mode=Node,RBAC,Webhook
# default AlwaysAllow

cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

### RBAC

- bound by namespace

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "get", "create", "update", "delete"]
- apiGroups: [""]
  resources: ["ConfigMap"]
  verbs: ["create"]
  resourceNames: ["foo", "bar"] # extra condition

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devuser-developer-binding
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io

kubectl get roles
kubectl get rolebindings

# check access
kubectl auth can-i delete nodes
kubectl auth can-i create deployments --as dev-user # admin only
kubectl auth can-i create deployments --as dev-user -n test # admin only

kubectl get pods --as dev-user

kubectl create role developer ...
kubectl create rolebinding dev-user-binding ...
```

## Cluster Roles

- roles that are not bound by namespace

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: secret-reader
rules:
- apiGroups: [""]
  #
  # at the HTTP level, the name of the resource for accessing Secret
  # objects is "secrets"
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
# This cluster role binding allows anyone in the "manager" group to read secrets in any namespace.
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io


kubectl api-resources
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding node-reader-binding --clusterrole=node-reader --user=michelle
```

## Admission Controller

- kubectl -> kube api server (authN & authZ) -> create a pod
- add admission controller for the following
  - what if only permit images from certain repository?
  - do not permit runAs root user
  - only permit certain capabilities (eg bloc MAC_ADMIN)
  - pod always has labels
- admission controllers
  - always pull images
  - default storage classes
  - event rate limit
  - namespace exists
  - namespace auto provision
  - namespace life cycle
  - ...
- NamespaceAutoProvision is not enabled by default
- NodeRestriction is not enabled by default

- Note that the `NamespaceExists` and `NamespaceAutoProvision` admission controllers are deprecated and now replaced by `NamespaceLifecycle` admission controller.
- The `NamespaceLifecycle` admission controller will make sure that requests to a non-existent namespace is rejected and that the default namespaces such as default, kube-system and kube-public cannot be deleted.
- Note also that `DefaultStorageClass` observes creation of `PersistentVolumeClaim` objects that do not request any specific storage class and automatically adds a default storage class to them. This way, users that do not request any special storage class do not need to care about them at all and they will get the default one.

```bash
kubectl exec kube-apiserver-controlplane -n kube-system -- kube-apiserver -h | grep enable-admission-plugins

ExecStart=/usr/local/bin/kube-apiserver ... \
  --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
  --disable-admision-plugins=DefaultStorageClass

## kube-apiserver edit should be made from the manifest file i.e. /etc/kubernetes/manifests/kube-apiserver.yaml
ps -ef | grep kube-apiserver | grep admission-plugins
```

### Validating & mutating admission controllers

- mutating admission controllers are executed before validating ones e.g. NamespaceAutoProvision followed by NamespaceExists

```bash
# DefaultStorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: default # add this if not existing
```

- external logic
- mutating admission webhook / validating admission webhook
- admission controller --- send AdmissionReview object --- admission webhook server

1. deploy webhook server
2. configure admission webhook

```yaml
apiVersion: admissionregistratin.k8s.io/v1
kind: ValidatingWebhookConfiguration #or MutatingWebhookConfiguration
metadata:
  name: "pod-policy.example.com"
webhooks:
  - name: "pod-policy.example.com"
    clientConfig:
      service:
        namespace: webhook-namespace
        name: webhoook-service
      caBundle: "..................."
      # or
      # url: "https://external-server.example.com"
    rules:
      - apiGroups: [""]
        apiversion: ["v1"]
        operations: ["CREATE"]
        resources: ["pods"]
        scope: "Namespaced"

kubectl -n webhook-demo create secret tls webhook-server-tls --cert /root/keys/webhhook-server-tls.crt --key /root/keys/webhook-server-tls.key

apiVersion: apps/v1
kind: Deployment
metadata:
  name: webhook-server
  namespace: webhook-demo
  labels:
    app: webhook-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webhook-server
  template:
    metadata:
      labels:
        app: webhook-server
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1234
      containers:
      - name: server
        image: stackrox/admission-controller-webhook-demo:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8443
          name: webhook-api
        volumeMounts:
        - name: webhook-tls-certs
          mountPath: /run/secrets/tls
          readOnly: true
      volumes:
      - name: webhook-tls-certs
        secret:
          secretName: webhook-server-tls
```

## API

### API Version

- eanble/disable api groups (eg enable alpha)

```bash
ExecStart=/usr/local/bin/kube-apiserver ... -- runtime-config=batch/v2alpha1 # comma separated groups
```

### API deprecation

- /api
  - /kodekloud.com
    - /v1/alpha1
      - /course
      - /webinar
- API elements may only be removed by incrementing the version of the API group e.g. /webinar can only be removed in v2
- /api
  - /kodekloud.com
    - /v1/alpha1
      - /course
      - /webinar
    - /v1/alpha2
      - /course
- API objects must be able to round-trip between API versions in a given release without information loss with the exception of while REST resources that do not exist in some version

- Other than the most recent API versions in each track, older API versions must be supported after their announced deprecation for a duration of no less than:
  - GA: 12 months or 3 releases (whichever is longer)
  - Beta: 9 months or 3 releases (whichever is longer)
  - Alpha: 0 releases
- an API version in a given track (i.e. GA version) may not be deprecated until a new API version at least as stable is released.

```bash
apiVersion: apps/v1beta1 --> apiVersion: apps/v1

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
kubectl convert -f <old-file> --output-version <new-api>
kubectl convert -f nginx.yaml --output-version apps/v1

# get api group
kubectl explain jobs

# get preferred version info
kubectl proxy 8001&
curl localhost:8001/apis/authorization.k8s.io
```

## Custom Resource Definition & Custom Controllers

### CRD

```bash
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: flighttickets.flights.com
spec:
  scope: Namespaced
  group: flights.com # api group
  names:
    kind: FlightTicket
    singllar: flightticket
    plural: flighttickets
    shortNames:
    - ft
  versions:
  - name: v1
    served: true
    storage: true
  schema:
    openAPIV3Schema:
      type: object
      properties:
        spec:
          type: object
          properties:
            from:
              type: string
            to:
              type: string
            number:
              type: integer
              minimum: 1
              maximum: 10
---
apiVersion: flights.com/v1
kind: FlightTicket
meetadata:
  name: my-flight-ticket
spec:
  from: Mumbai
  to: Londom
  number: 2
```

### Custom controllers

- https://github.com/kubernetes/sample-controller

### Operator framework

- consolidate CRD and controller
- https://operatorhub.io
- https://developers.redhat.com/articles/2021/09/07/build-kubernetes-operator-six-steps

## Deployment strategy

- recreate, rollingupdate (default)

### Blue Green

- blue (old), green (new)
- change traffic when tests complete

- blue (label version: v1)
- green (label version: v2)
- change label selector of service

```bash
apiVersion: v2
kind: Service
metadata:
  name: my-service
spec:
  selector:
    version: v1
```

### Canary

- majority traffic to old, small percentage to new
- primary (label version: v1 app: front-end), canary (label version: v2 app: front-end), note common label
- adjust replicas between primary and canary
- specific % traffic routing needs service mesh (eg isto)

```bash
apiVersion: v2
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: front-ennd
```

## Helm

### Install Helm

```bash
helm install workpress ...
helm upgrade wordpress ...
helm rollback wordpress ...
helm uninstall wordpress ...

cat /etc/os-release
```

### Helm concepts

- https://artifacthub.io/

```bash
## template + Values.yaml + Chart.yaml (info about chart eg name, apiversion ...) = helm chart
# template/deployemnt.yaml
{{ .Values.image }}

# Values.yaml
image: wordpress:4.8-apache


helm search hub wordpress # from artifacthub.io

helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo wordpress
helm repo list

helm install [release-name] [chart-name]
helm install release-1 bitnami/wordpress
helm install release-2 bitnami/wordpress
helm install release-3 bitnami/wordpress

helm list
helm uninstall [release-name]
helm pull --untar bitnami/wordpress # only download
ls wordpress
helm install release-4 ./wordpress
```
