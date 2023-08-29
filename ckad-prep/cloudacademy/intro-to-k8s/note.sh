#### 1. Pod
kubectl run mypod --image nginx:latest --port 80 --labels=app=webserver \
  --dry-run=client -o yaml > 01_pod.yaml # updated resource attributes

#### 2. Service
# label not necessarily match to pod label
kubectl create service nodeport webserver --tcp=80 \
  --dry-run=client -o yaml
# label matches but cannot select NodePort
kubectl expose pod mypod --port=80 \
  --dry-run=client -o yaml
# create both pod and service
kubectl run mypod --image nginx:latest --port 80 --labels=app=webserver --expose \
  --dry-run=client -o yaml

#### 3.Multi-Container Pod
kubectl create ns microservice \
  --dry-run=client -o yaml > 04_namespace.yaml
# need to update label indenpendently

kubectl create -f intro-to-k8s/src/3.2-multi_container.yaml -n microservice
kubectl logs app counter --tail 10 -n microservice
kubectl delete -f intro-to-k8s/src/3.2-multi_container.yaml -n microservice

#### 4. Service Discovery
kubectl run data-tier --image redis --port 6379 \
  --image-pull-policy=IfNotPresent \
  --labels=app=microservice,tier=data --expose \
  --dry-run=client -o yaml

kubectl run app-tier --image lrakai/microservices:server-v1 --port 8080 \
  --env=REDIS_URL=redis://data-tier:6379 \
  --labels=app=microservices,tier=app --expose \
  --dry-run=client -o yaml

kubectl run support-tier --image lrakai/microservices:counter-v1 \
  --env=API_URL=http://app-tier.service-discovery:8080 \
  --labels=app=microservices,tier=support \
  --dry-run=client -o yaml > 04_support.yaml

#### 5. Deployments
kubectl create deploy data-tier --image redis --port 6379 \
  --dry-run=client -o yaml > 05_data.yaml
kubectl create -f 05_data.yaml
kubectl expose deploy data-tier --port=6379 \
  --dry-run=client -o yaml

kubectl create deploy app-tier --image lrakai/microservices:server-v1 --port 8080 \
  --dry-run=client -o yaml > 05_app.yaml
kubectl create -f 05_app.yaml
kubectl expose deploy app-tier --port 8080 \
  --dry-run=client -o yaml

kubectl create deploy support-tier --image lrakai/microservices:counter-v1 \
  --dry-run=client -o yaml > 05_support.yaml
kubectl create -f 05_support.yaml
kubectl scale deploy support-tier --replicas 5

kubectl scale deploy app-tier --replicas 5
kubectl describe svc app-tier # endpoints updated

kubectl delete -f 05_app.yaml -f 05_data.yaml -f 05_support.yaml
kubectl delete svc app-tier data-tier

#### 6. Autoscaling
## scale automatically based on CPU utilization (or custom metrics)
## CPU
##    set target CPU along with min/max replicas
##    target CPU is expressed as a percentage of the pod's CPU request
## Custom metrics
##    metrics server is one solution for collecting metrics - https://github.com/kubernetes-sigs/metrics-server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
minikube addons enable metrics-server
kubectl top pod

kubectl apply -f 06_app.yaml

kubectl autoscale deployment app-tier --max=5 --min=2 --cpu-percent=70 \
  --dry-run=client -o yaml
kubectl get hpa
kubectl edit hpa app-tier

#### 7. Rolling Updates and Rollbacks
## any change to a deployment template triggers a rollout
## different rollout strategies are avaialbe - Recreate, RollingUpdate
## kubectl rollout commands - status, pause, resume, rollback (undo), rollout
kubectl create -f 07_data.yaml \
  && kubectl expose deploy data-tier --port=6379 \
  && kubectl create -f 07_app.yaml \
  && kubectl expose deploy app-tier --port 8080 \
  && kubectl create -f 07_support.yaml

kubectl edit deploy app-tier # container name to cloudacademy

kubectl rollout status deploy app-tier
kubectl rollout pause deploy app-tier
kubectl rollout resume deploy app-tier
kubectl rollout history deploy app-tier
kubectl rollout undo deployment app-tier

kubectl delete -f 07_app.yaml -f 07_data.yaml -f 07_support.yaml
kubectl delete svc app-tier data-tier

#### 8. Probes & Init Containers
## readiness probes (not serve traffic if not ready) and liveness probes (restart if not live)
## HTTP GET, TCP socket, exec

## Data tire (redis)
## liveness - open tcp socket
## readiness - readis-cli ping command

## Ap ptier (server)
## liveness - HTTP GET /probe/liveness
## readiness - hTTP GET /probe/readiness

## init container has all the same attributes to container except for readinessProbe

kubectl expose deploy data-tier --port=6379

kubectl delete -f 08_app.yaml -f 08_data.yaml
kubectl delete svc data-tier

kubectl logs app-tier-dcc76dbf9-wmj5v await-redis

#### 9. Volumes
## volumes vs persistent volumes - diff is how their lifetime is managed
## pvc access mode - read-write-once, read-only many or read-write many
## pvc is pending if no pv can satisfy it and dynamic provisioning is not enabled

kubectl create -f 09_data.yaml
kubectl expose deploy data-tier --port=6379

kubectl create -f 09_app.yaml
kubectl expose deploy app-tier --port 8080

kubectl create -f 09_support.yaml

kubectl delete -f 09_app.yaml -f 09_data.yaml -f 09_support.yaml
kubectl delete svc app-tier data-tier

#### 10. ConfigMaps and Secrets
kubectl create -f 10_data.yaml
kubectl expose deploy data-tier --port=6379

# check volume content
# kubectl exec -it data-tier-7ccf89ddc5-9rspm -- cat /etc/redis/redis.conf

# change of config map value ensures the volume content gets updated i.e. tcp-keepalive 240 -> 500
#>> however redis pod is not restarted, to restart do the following
kubectl rollout restart deploy data-tier

kubectl create secret generic app-tier-secret --from-literal=api-key=LRcAmM1904ywzK3esX

kubectl create -f 10_app.yaml
kubectl expose deploy app-tier --port 8080

#>> new secret value will change environment value but normally it won't be reloaded by an app
# >> better to rollout like previous volume example
# kubectl exec app-tier-75c5769b66-xnvjj -- env

kubectl create -f 10_support.yaml

kubectl delete -f 10_app.yaml -f 10_data.yaml -f 10_support.yaml
kubectl delete svc app-tier data-tier

#### Multi-container Patterns
## sidecar
# helper container to assist a primary container
# logging, file syncing, watchers ...

# primary - web server
# sidecar - content puller
# share volume

## ambassador
# ambassador container is a proxy for communicating to/from the primary container
# communicating with databases eg) primary always connect to localhost

# primary container - web app
# ambassador - database proxy

## adapter
# standardized interface across multiple pods
# normalizing output logs and monitoring data

#### Leveraging kubectl
## shell completion
# source <(eksctl completion bash)
kubectl completion --help
# source <(kubectl completion bash)
# source <(helm completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc
kubectl get <double-tab>

## short names
kubectl api-resources

## list resources
kubectl get po -A
kubectl get po --show-labels -A # show all labels
kubectl get po -A -L k8s-app # show specific labels
kubectl get po -A -L k8s-app -l k8s-app # filter and show specific labels
kubectl get po -A -L k8s-app -l k8s-app=kube-proxy
kubectl get po -A -L k8s-app -l k8s-app!=kube-proxy,k8s-app

kubectl get po -n kube-system --sort-by=metadata.creationTimestamp
kubectl get po -n kube-system --sort-by='{.metadata.creationTimestamp}'

## explain resources
kubectl explain po
kubectl explain po.spec.containers
kubectl explain po.spec.containers.resources

kubectl explain po.spec.containers.resources --recursive
