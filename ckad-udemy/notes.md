# CORE CONCEPTS

## Practice Test - Pods

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

## Practice Test - ReplicaSets

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
```

## Practice Test - Deployments

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

## Practice Test - Namespaces

- Namespace
- ResourceQuota

```bash
kubectl create ns dev

kubectl get pod --namespace=dev #(or -n=dev)

kubectl config set-context $(kubectl congig current-context) --namespace=dev
kubectl get pod

kubectl get pods --all-namespaces
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
