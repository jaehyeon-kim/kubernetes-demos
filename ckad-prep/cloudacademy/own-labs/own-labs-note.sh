###### create a simple sidecar logger
###### create a PV/PVC and associated with a pod
###### create config map and associate with a pod in 3 ways
###### create secret and associate with a pod in 3 ways
###### create a container that uses an ephemeral volume
cat > ephemeral.yaml << EOL
apiVersion: v1
kind: Pod
metadata:
  name: ephemeral
spec:
  volumes:
  - name: ephemeral
    emptyDir: {}
  containers:
  - image: busybox
    name: writer
    command:
    - sh
    - -c
    - 'i=1; while true; do echo "run $i" >> /tmp/log.log; i=$((i+1)); sleep 2; done'
    volumeMounts:
    - name: ephemeral
      mountPath: /tmp
  - image: busybox
    name: reader
    command:
    - sh
    - -c
    - 'while true; do tail /tmp/log.log -n 1; sleep 2; done'
    volumeMounts:
    - name: ephemeral
      mountPath: /tmp
EOL

###### create a network policy - egress ip block & pod selector (https://ip-api.com/#8.8.8.8)
## 1. create a network policy where only tier=cache can access tier=web
cat > netpol-ingress.yaml <<EOL
EOL

## 2. create a network policy where all outbound traffic is allowed except for 8.8.8.8/32

###### statefulset w/ headless service
# https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/
# kubernetes dashboard

#       command:
#         - sh
#         - -c
#         - 'i=1; while true; do echo "run $i" >> /tmp/log.log; i=$((i+1)); sleep 2; done'

#       command:
#         - sh
#         - -c
#         - "while true; do tail /tmp/log.log -n 1; sleep 2; done"


## StatefulSet

# dynamically provision two 1GiB volumes prior to starting this tutorial
cat > statefulset-pv.yaml <<EOL
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-1
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/pv0001
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-2
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/pv0002
EOL

cat > statefulset-web.yaml <<EOL
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
      volumeClaimTemplate:
      - metadata:
          name: www
        spec:
          storageClassName: manual
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
EOL