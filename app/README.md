# Table of Contents

- [1. Create the Docker image](#create-docker-image)
- [2. Deploy the app to Kubernetes](#kubernetes-deploy)
  - [2.1. Push the image to Minikube's Registry](#registry)
  - [2.2. Create the Deployment](#deployment)
  - [2.3. Create the Service](#service)
  - [2.4. Create the Ingress](#ingress)
  - [2.5. Testing](#testing)
- [3. Deployment with HELM](#helm)


# Deploy a React application to Kubernetes

To deploy our React app on Kubernetes, we have to bake a Docker image first.

Once we have the image, we have to upload it to a registry which is accessible by the Kubernetes. In our case this is going
to be registry running inside the Minikube VM.

After this point, we have to create several different resources to make our app running on Kubernetes, namely these:

- `Deployment` which creates the Pods.
- `Service`, which exposes out Deployment.
- `Ingress`, which makes our Service accessible from outside of the Kubernetes cluster.

## <a id="create-docker-image"></a> 1. Build a Docker image

Create a Dockerfile with the following content:

```bash
# Content of frontend.Dockerfile
FROM node:16.11.1-alpine as BUILD
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY package.json ./
COPY package-lock.json ./
RUN npm ci --silent
RUN npm install react-scripts -g --silent
COPY . ./
RUN npm run build

FROM nginx:stable-alpine
COPY --from=BUILD /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Here, we take advantage of the multistage build pattern. First we create a temporary image (called BUILD) which is used for building the artifact, then the files created during the build phase, are copied
to the production image.

To build this image, execute the following command (assuming you are in the respository's root folder):

```bash
docker build \
  -f app/frontend.Dockerfile \
  -t hello-kube-react \
  app/frontend/
```

Once the build completed, you can validate your image by running it, simply create a docker container from it by executing the following command:

```bash
docker run -it --rm -p 8080:80 hello-kube-react
```

After this, you can access your app using this address in your browser: `http://localhost:8080`

## <a id="kubernetes-deploy"></a> 2. Deploy the app to Kubernetes

### <a id="registry"></a> 2.1. Push the image to Minikube's Registry

At this point, the Docker image we created earlier exists only on our local machine. We need to push it to the registry running inside Minikube.

To do so, execute the following command:

```bash
docker tag hello-kube-react localhost:5000/hello-kube-react
docker push localhost:5000/hello-kube-react
```

After the image is pushed, refer to it by `localhost:5000/hello-kube-react` in kubectl specs.

### <a id="deployment"></a> 2.2. Create the Deployment

First you have to create a resource called `Deployment`, which uses the docker image we created earlier in this document (hello-kube-react:latest)

Here is the content of the `Deployment`:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-kube-react
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-kube-react
  template:
    metadata:
      labels:
        app: hello-kube-react
    spec:
      containers:
      - name: hello-kube-react
        image: localhost:5000/hello-kube-react:latest
        resources:
          limits:
            memory: "250Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
```

It is going to create 2 `Pods` from the `hello-kube-react` Docker image, with 2 replicas.

### <a id="service"></a> 2.3. Create the Service

Expose your Deployment using a Service resource:

```bash
apiVersion: v1
kind: Service
metadata:
  name: hello-kube-react
spec:
  type: NodePort
  selector:
    app: hello-kube-react
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

### <a id="ingress"></a> 2.4. Create the Ingress

Make your service available outside from your cluster by creating an Ingress resource:

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-kube-react
spec:
  rules:
    - host: hello-react.kube
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hello-kube-react
                port:
                  number: 80
```

### <a id="testing"></a> 2.5. Testing

Visit the following address in your browser: `http://hello-react.kube`

If everything is working fine, you should see your react app in your browser, which is deployed in your minikube environment.


## <a id="helm"></a> 3. Deployment with HELM

Based on the steps in this document, I've created a Helm package to make the deployment easier.

This Helm package will create

- A `Deployment` containing 2 Pods (by default)
- A `Service`, which exposes the `Deployment`
- An `Ingress`, which makes the `Service` available outside of the cluster

To deploy the helm package use the following command:

```bash
helm upgrade --install \
  hello-kube-react \
  app/frontend-helm
```

Then verify the deployment via:

```bash
$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
hello-kube-react        default         1               2021-11-08 18:28:20.782716927 +0100 CET deployed        hello-kube-react-0.1.0  0.0.1 
```