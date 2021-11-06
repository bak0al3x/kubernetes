# Kubernetes Environment Setup

This tutorial is written by the steps I took on my Arch Linux environment to install a local development K8s using minikube.

## 1. Install Docker

Install the package

```bash
sudo pacman -S docker
```

Validate the installation

```bash
docker -v
Docker version 20.10.10, build b485636f4b
```

Check if the `docker` service is running

```bash
systemctl status docker
○ docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
     Active: inactive (dead)
TriggeredBy: ○ docker.socket
       Docs: https://docs.docker.com
```

To be able to manage docker as a non-root user, we need to create a special group, and add our user to it.

First, create the group:

```bash
sudo groupadd docker
groupadd: group 'docker' already exists
```

Seems like it already exists. Now we need to add our user to it:

```bash
sudo usermod -aG docker $(whoami)
```

We cal also validate if our user has been added to the `docker` group:

```bash
cat /etc/group | grep docker
docker:x:970:bakoa
```

Now we have to log out from our session, so our group-memberships are re-evaulated.

Start the docker service:

```bash
sudo systemctl start docker
```

Validate if the service running


```bash
systemctl status docker
○ docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
     Active: inactive (dead)
TriggeredBy: ○ docker.socket
       Docs: https://docs.docker.com
[bakoa@archibald kubernetes]$ sudo systemctl start docker
[bakoa@archibald kubernetes]$ systemctl status docker
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
     Active: active (running) since Sat 2021-11-06 12:27:08 CET; 4s ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 1886 (dockerd)
      Tasks: 36 (limit: 18958)
     Memory: 142.4M
        CPU: 189ms
     CGroup: /system.slice/docker.service
             ├─1886 /usr/bin/dockerd -H fd://
             └─1906 containerd --config /var/run/docker/containerd/containerd.toml --log-level info
...
...
```

(Optional) Enable the startup of the `docker` service after boot

```
sudo systemctl enable docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
```

Test the docker installation

```bash
docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
2db29710123e: Pull complete 
Digest: sha256:37a0b92b08d4919615c3ee023f7ddb068d12b8387475d64c622ac30f45c29c51
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

## 2. Install minikube

**About Kubernetes**

Kubernetes is an open source container orchestration engine for automating deployment, scaling and management of containerized applications.

**About minikube**

minikube is a tool that lets you run Kubernetes locally. minikube runs a single-node Kubernetes cluster on your personal computer, so that you can try out Kubernetes, or for daily development work.

To install minikube, the first step is to check, if virtualization is supported on your OS.

Run the following command, and verify that the output is non-empty:

```bash
grep -E --color 'vmx|svm' /proc/cpuinfo | wc -l
32
```

### 2.1. Install kubectl

On ArchLinux, the kubectl is available in the repositories, so install it with the following command:

```bash
sudo pacman -S kubectl
```

Ensure that the version you installed is up to date:

```bash
kubectl version --client
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.3", GitCommit:"c92036820499fedefec0f847e2054d824aea6cd1", GitTreeState:"archive", BuildDate:"2021-10-28T06:55:39Z", GoVersion:"go1.17.2", Compiler:"gc", Platform:"linux/amd64"}
```

### 2.2. Install a Hypervisor

You can use either KVM or VirtualBox. minikube also supports the use of the podman driver (which is similar to the Docker driver), but that one requires to run Podman as superuser privilige. In this tutorial I'll stick to the KVM

Check if the virtualization is enabled on your system:

```bash
LC_ALL=C lscpu | grep Virtualization
Virtualization:                  VT-x
```

As I have an Intel CPU, this output seems to be fine.

Now check if we have the proper Kernel modules to run KVM:

```bash
zgrep CONFIG_KVM_INTEL /proc/config.gz
CONFIG_KVM_INTEL=m
```

This output is also fine. Accepted values for the `CONFIG_KVM_INTEL` are either `m` or `y`. If you have and AMD cpu, replace the `CONFIG_KVM_INTEL` with `CONFIG_KVM_AMD` in the zgrep command.

Now install the KVM:

```bash
sudo pacman -S virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat dmidecode
```

Now active the KVM service to be launched at startup:

```bash
sudo systemctl enable libvirtd.service
Created symlink /etc/systemd/system/multi-user.target.wants/libvirtd.service → /usr/lib/systemd/system/libvirtd.service.
Created symlink /etc/systemd/system/sockets.target.wants/virtlockd.socket → /usr/lib/systemd/system/virtlockd.socket.
Created symlink /etc/systemd/system/sockets.target.wants/virtlogd.socket → /usr/lib/systemd/system/virtlogd.socket.
Created symlink /etc/systemd/system/sockets.target.wants/libvirtd.socket → /usr/lib/systemd/system/libvirtd.socket.
Created symlink /etc/systemd/system/sockets.target.wants/libvirtd-ro.socket → /usr/lib/systemd/system/libvirtd-ro.socket.
```

Also start the KVM service:

```bash
[bakoa@archibald kubernetes]$ sudo systemctl start libvirtd.service
[bakoa@archibald kubernetes]$ sudo systemctl status libvirtd.service
● libvirtd.service - Virtualization daemon
     Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: disabled)
     Active: active (running) since Sat 2021-11-06 13:03:49 CET; 4s ago
TriggeredBy: ● libvirtd-admin.socket
             ● libvirtd-ro.socket
             ● libvirtd.socket
       Docs: man:libvirtd(8)
             https://libvirt.org
   Main PID: 5134 (libvirtd)
      Tasks: 19 (limit: 32768)
     Memory: 9.7M
        CPU: 88ms
     CGroup: /system.slice/libvirtd.service
             └─5134 /usr/bin/libvirtd --timeout 120
```

Now replace the libvirtd.conf file under the /etc/libvirt directory with the one in this directory:

```bash
sudo cp libcirtd.conf /etc/libvirt/libvirtd.conf
```

Then add your user user account to the `libvirt` group:

```bash
sudo usermod -aG libvirt $(whoami)
cat /etc/group | grep libvirt
libvirt:x:969:bakoa
```

Set the default kvm network to autostart

```bash
sudo virsh net-autostart default
```

And then restart the libvirtd service to apply changes:

```bash
[bakoa@archibald kubernetes]$ sudo systemctl restart libvirtd.service
[bakoa@archibald kubernetes]$ sudo systemctl status libvirtd.service
● libvirtd.service - Virtualization daemon
     Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: disabled)
     Active: active (running) since Sat 2021-11-06 13:09:19 CET; 3s ago
TriggeredBy: ● libvirtd-admin.socket
             ● libvirtd-ro.socket
             ● libvirtd.socket
       Docs: man:libvirtd(8)
             https://libvirt.org
   Main PID: 6002 (libvirtd)
      Tasks: 19 (limit: 32768)
     Memory: 6.5M
        CPU: 85ms
     CGroup: /system.slice/libvirtd.service
             └─6002 /usr/bin/libvirtd --timeout 120
```

### 2.3. Install minikube

On ArchLinux, the minikube package is available in the repositories. To install it, execute the following command:

```bash
sudo pacman -S minikube
```

(Optional) Configure minikube's CPU, RAM and Hypervisor driver settings:

```
minikube config set cpus 4
minikube config set memory 4096
minikube config set driver kvm2
```

To confirm successful installation of both the hypervisor and Minikube, run the following command to startup a local Kubernetes cluster:

```bash
minikube start --driver=kvm
```

Once minikube start finishes, run the following command below to check the status of the cluster:

```bash
minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

If your output is similar to this, then you've successfully installed a local kubernetes environment on your machine using minikube, enjoy :)

### 2.4. Validate minikube installation

First open the kubernetes dashboard in your browser by executing the following command in your terminal:

```bash
minikube dashboard
```

Create a deployment using the `kubectl create` command. This Pod runs a Container based on the provided Docker image.

```bash
kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
deployment.apps/hello-node created

kubectl get deployments
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
hello-node   1/1     1            1           9s
```

Check the status of the Pod:

```bash
kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
hello-node-7567d9fdc9-rpnql   1/1     Running   0          57s
```

Everything seems fine here, now create a `Service`. By default, the Pod is only accessible by its internal IP address within the Kubernetes cluster. To make the `hello-node` Container accessible from outside the Kubernetes virtual network, you have to expose the Pod as a Kubernetes Service.

To do so, execute the following command in your terminal:

```bash
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
service/hello-node exposed

kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
hello-node   LoadBalancer   10.109.26.234   <pending>     8080:31799/TCP   4s
kubernetes   ClusterIP      10.96.0.1       <none>        443/TCP          5m42s
```

The output should look like this. On cloud providers that supports load balancers, an external IP address would be provisioned to access the Service. On minikube, the `LoadBalancer` type makes the Service accessible through the `minikube service` command.

Run the following command:

```bash
minikube service hello-node
```

This opens up a browser window that serves your app and shows the app's response.