import os
from flask import Flask
app = Flask(__name__)

@app.route('/')
def index():
    appname = os.environ['APP_NAME']
    response = "%s - %s\n" %('Hello World', appname)
    return response

==

FROM python:3

RUN pip install flask

RUN mkdir -p /corp/app
WORKDIR /corp/app
COPY main.py .
ENV FLASK_APP=/corp/app/main.py

ENV APP_NAME=CloudAcademy.DevOps.K8s

CMD ["flask", "run", "--host=0.0.0.0"]

==

k config set-context --current --namespace=cloudacademy

==

# nginx.configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: cloudacademy
data:
  nginx.conf: |-
    #CODE1.0:
    #add the nginx.conf configuration - this will be referenced within the deployment.yaml
    server {
        listen 80;
        server_name localhost;

        location / {
        proxy_pass http://localhost:5000/;
        proxy_set_header Host "localhost";
        }
    }

==
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: cloudacademy
  labels:
    role: frontend
    env: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      role: frontend
  template:
    metadata:
      labels:
        role: frontend
    spec:
      containers:
      #CODE2.0:
      #add the NGINX container to the pod - configure it to mount the nginx.conf file stored in the nginx-conf configMap 
      - name: nginx
        image: nginx:1.13.7
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 80
        volumeMounts:
        - name: nginx-proxy-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
      #CODE2.1:
      #add the FLASK container to the pod
      - name: flask
        image: cloudacademydevops/flaskapp
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 5000
        env:
        - name: APP_NAME
          value: CloudAcademy.DevOps.K8s.Manifest
      volumes:
      #CODE2.2:
      #reference the nginx-conf configMap - this will be mounted into the NGINX container
      - name: nginx-proxy-config
        configMap:
          name: nginx-conf


k expose deploy frontend --port=80 --target-port=80
curl -i http://10.111.208.248

==============

helm create test-app
helm template test-app

helm package app
#app-0.1.0.tgz
helm install cloudacademy app-0.1.0.tgz

cp app/values.yaml app/values.dev.yaml
cp app/values.yaml app/values.prod.yaml

helm upgrade cloudacademy app-0.1.0.tgz -f app/values.dev.yaml
helm upgrade cloudacademy app-0.1.0.tgz -f app/values.prod.yaml

#helm template cloudacademy -f ./app/values.prod.yaml ./app | kubectl apply -f -

====
# Chart.yaml
apiVersion: v1
appVersion: "1.0"
description: CloudAcademy DevOps K8s Lab
name: app
version: 0.1.0

# values.yaml

# Default values for app.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: nginx
  tag: stable
  pullPolicy: IfNotPresent

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name:

podSecurityContext: {}
  # fsGroup: 2000

securityContext: {}
  # capabilities:
  #   drop:
  #   - ALL
  # readOnlyRootFilesystem: true
  # runAsNonRoot: true
  # runAsUser: 1000

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: chart-example.local
      paths: []

  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

nodeSelector: {}

tolerations: []

affinity: {}

#CODE3.0:
#create new configuration value which will store a message to be passed into the Flask web app as an environment variable
webapp:
  message: CloudAcademy.DevOps.K8s.Helm

===
# _helpers.tpl
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
helm.sh/chart: {{ include "app.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

===
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullname" . }}
  labels:
{{ include "app.labels" . | indent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: {{ include "app.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}