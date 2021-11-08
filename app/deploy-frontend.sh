#!/usr/bin/env bash

IMAGE_NAME="hello-kube-react"

# Build the Docker image
docker build \
    -f app/frontend.Dockerfile \
    -t "$IMAGE_NAME" \
    app/frontend

# Push the Docker image to Minikube's registry
docker tag \
    "$IMAGE_NAME" \
    "localhost:5000/$IMAGE_NAME"

docker push "localhost:5000/$IMAGE_NAME"

# Create Deployment resource
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $IMAGE_NAME
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $IMAGE_NAME
  template:
    metadata:
      labels:
        app: $IMAGE_NAME
    spec:
      containers:
      - name: $IMAGE_NAME
        image: localhost:5000/$IMAGE_NAME
        resources:
          limits:
            memory: "250Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
EOF

# Create the Service resource
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: $IMAGE_NAME
spec:
  type: NodePort
  selector:
    app: $IMAGE_NAME
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

# Create the Ingress resource
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $IMAGE_NAME
spec:
  rules:
    - host: hello-react.kube
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: $IMAGE_NAME
                port:
                  number: 80
EOF