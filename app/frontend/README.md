# Run a React app in Kubernetes

## 1. Create a new react app

### 1.1. Pre-Requisites

First step is to install `nodejs` and `npm` (node package manager) packages on our system. To do so, execute the following command:

```bash
$ sudo pacman -S nodejs npm
```

For managing node versions, I like to use an npm package called `n`. With this, we can easily switch between different versions of nodejs.
To install it, execute the following command:

```bash
$ sudo npm i -g n
```

*NOTE: Sudo rights are required for this installation, as the `-g` switch tells to npm to install the provided package globally, hence the npm will try to write locations which may not be available for normal users.*

As for now, I'll stick with the LTS version of nodejs. To do so, execute the following command:

```bash
$ sudo n lts
  installing : node-v16.13.0
       mkdir : /usr/local/n/versions/node/16.13.0
       fetch : https://nodejs.org/dist/v16.13.0/node-v16.13.0-linux-x64.tar.xz
   installed : v16.13.0 (with npm 8.1.0)
```

For the last step, install `Create React App` globally:

```bash
sudo npm i -g create-react-app
```

### 1.2. Create the example app

You can easily create a new Reactjs application via the create-react-app command, execute the following command:

```bash
$ create-react-app frontend --template typescript
```

*NOTE: Use of typescript template is not mandatory*

### 1.3. Testing the example app

First you have to start a node development server locally. To accomplish this task you have to execute the following command from the project's root directory:

```bash
$ npm start
```

On Linux, this opens a new tab in your default browser, and opens the `http://localhost:3000` address. Now you can close the tab in the browser, also you can stop your loval node dev server.

## 2. Create the Docker image

Add the following Docker file to the project:

```bash
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
docker build -f app/frontend/Dockerfile -t example-react-app app/frontend/
```

Once the build completed, you can validate your image by running it, simply create a docker container from it by executing the following command:

```bash
$ docker run -it --rm -p 8080:80 example-react-app
```

After this, you can access your app using this address in your browser: `http://localhost:8080`

## 3. Deploy the app to Kubernetes

### 3.1. Docker registry

At this point, the Docker image we created earlier exists only on our local machine. We need a registry server accessible by both our local machine, and the Kubernetes running in the minikube VM.

First, we have to enable the `registry` addon for minikube:

```bash
$ minikube addons enable registry
```

Then verify the service:

```bash
$ kubectl get svc -n kube-system
NAME       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10     <none>        53/UDP,53/TCP,9153/TCP   19m
registry   ClusterIP   10.105.61.46   <none>        80/TCP,443/TCP           16m
```

When enabled, the registry addon exposes its port 5000 on the minikube’s virtual machine.

In order to make docker accept pushing images to this registry, we have to redirect port 5000 on the docker virtual machine over to port 5000 on the minikube machine. We can (ab)use docker’s network configuration to instantiate a container on the docker’s host, and run socat there:

```bash
docker run \
    --rm \
    -it \
    -d \
    --network=host \
    alpine \
    ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"
```

Once socat is running it’s possible to push images to the minikube registry:

```bash
docker tag example-react-app localhost:5000/example-react-app
docker push localhost:5000/example-react-app
```

After the image is pushed, refer to it by `localhost:5000/example-react-app` in kubectl specs.

### 3.2. Create the Deployment

First you have to create a resource called `Deployment`, which uses the docker image we created earlier in this document (example-react-app:latest)

Here is the content of the `Deployment`:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-react-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: example-react-app
  template:
    metadata:
      labels:
        app: example-react-app
    spec:
      containers:
      - name: example-react-app
        image: localhost:5000/example-react-app:latest
        resources:
          limits:
            memory: "250Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
```

It is going to create 2 `Pods` from the `example-react-app` Docker image, with 2 replicas.

### 3.3. Create the Service

Expose your Deployment using a Service resource:

```bash
apiVersion: v1
kind: Service
metadata:
  name: example-react-app
spec:
  type: NodePort
  selector:
    app: example-react-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

### 3.4. Create the Ingress

Make your service available outside from your cluster by creating an Ingress resource:

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-react-app
spec:
  rules:
    - host: hello-react.kube
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: example-react-app
                port:
                  number: 80
```

### 3.5. Testing

Visit the following address in your browser: `http://hello-react.kube`

If everything is working fine, you should see your react app in your browser, which is deployed in your minikube environment.


### 3.6. Adding helm package

I've created a helm package for the whole deployment process. To install it execute the following command:

```bash
$ helm upgrade --install hello-react-helm ./helm/react-frontend/
```

Then verify the deployment via:

```bash
$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
hello-react-helm        default         1               2021-11-07 21:27:03.145288085 +0100 CET deployed        react-frontend-0.1.0    1.16.0 
```