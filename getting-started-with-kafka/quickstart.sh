minikube start --cpus='4' --memory=6144 --addons=metrics-server

# Deploy Strimzi using installation files
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Create an Apache Kafka cluster
kubectl apply -f https://strimzi.io/examples/latest/kafka/kafka-persistent-single.yaml -n kafka

# Send and receive messages
kubectl run kafka-producer --image=quay.io/strimzi/kafka:0.37.0-kafka-3.5.1 -it --rm --restart=Never -n kafka \
 -- bin/kafka-console-producer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic my-topic

kubectl run kafka-consumer --image=quay.io/strimzi/kafka:0.37.0-kafka-3.5.1 -it --rm --restart=Never -n kafka \
  -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic my-topic --from-beginning

# Deleting your Apache Kafka cluster
kubectl delete $(kubectl get strimzi -o name -n kafka) -n kafka

# Deleting the Strimzi cluster operator
kubectl -n kafka delete -f 'https://strimzi.io/install/latest?namespace=kafka'

kubectl delete ns kafka