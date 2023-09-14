# Get Started! - https://minikube.sigs.k8s.io/docs/start/
# Using Multi-Node Clusters - https://minikube.sigs.k8s.io/docs/tutorials/multi_node/
# Accessing apps (NodePort & LoadBalancer) - https://minikube.sigs.k8s.io/docs/handbook/accessing/

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && sudo install minikube-linux-amd64 /usr/local/bin/minikube \
  && rm minikube-linux-amd64

# https://minikube.sigs.k8s.io/docs/tutorials/volume_snapshots_and_csi/

minikube start --cni calico --addons=metrics-server

minikube start --nodes 2 --cni calico --addons=metrics-server --memory=max --cpu=max

# minikube start --addons=dashboard --addons=registry

minikube delete

minikube start --cni calico # w/ calico network plugin
minikube addons enable metrics-server

minikube dashboard --url

============

minikube start --nodes 2 -p demo

minikube start --cni calico # w/ calico network plugin

minikube profile list

kubectl get po -A

minikube -p demo addons enable metrics-server
minikube dashboard -p demo


minikube pause -p demo

minikube unpause -p demo

minikube stop -p demo

minikube config set memory 9001 -p demo

minikube -p demo addons list

minikube start -p demo --kubernetes-version=v1.16.1

minikube delete --all -p demo