<!-- Kubernetes Crash Course: Learn the Basics and Build a Microservice Application
Training - https://www.youtube.com/watch?v=XuSQU5Grv1g
Lab - https://kode.wiki/kubernetes-labs -->

```bash
https://kode.wiki/kubernetes-labs

kubectl apply -f deployment-definition.yml
kubectl set image deployment/myapp-deployment nginx-container=nginx:1.9.1

Service

ClusterIP: not exposed outside
NodePort: exposed on port of node
LoadBalancer: distribute traffic into different services

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

curl http://192.168.1.2:30008


docker run -d --name=redis redis
docker run -d --name=db postgres:9.4
docker run -d --name=vote -p 5000:80 --link redis:redis voting-app
docker run -d --name=result -p 5001:80 --link db:db result-app
docker run -d --name=worker --link redis:redis --link db:db worker

Goals
1. Deploy containers
2. Enable connectivity
3. External access

Steps
1. Deploy Pods
2. Create services (ClusterIP)
  1. redis
  2. db
3. Create services (NodePort)
  1. voting-app
  2. result-app

kodekloudhub/example-voting-app
```
