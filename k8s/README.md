# Table of Contents

- [1. Install with the provided Bash script/Ansible.](#install-with-ansible)
- [2. Manual Install](#manual-install)
    - [2.1. Install and configure Docker](#docker)
    - [2.2. Install the KVM Hypervisor](#hypervisor)
    - [2.3. Install Minikube](#minikube)
    - [2.4. Install HELM Package Manager](#helm)
    - [2.5. Enable the Ingress addon for Minikube](#ingress)
    - [2.6. Enable the Ingress-DNS addon for Minikube](#ingress-dns)
    - [2.7 Enable the Registory addon for Minikube](#registry)

# Kubernetes Environment Setup

This is a tutorial to install a local Kubernetes development environment using Minikube on my Arch based system.

## <a id="install-with-ansible"></a> 1. Install with the provided Bash script/Ansible.

I've written an automated installation script with Bash and Ansible, which sets up everything for you, and in a
matter of seconds you'll have a working Minikube environment.

To use the script just execute the following command (assuming you're in the root of the repostiroy):

```bash
cd k8s && ./setup-minikube.sh
```

This script will:

- Install `Ansible`
- Install and configure `Docker`
- Install and configure `KVM` as the Hypervisor for Minikube.
- Install and configure `Minikube`, the local development K8s environment.
- Install and configure `Helm`, which is a package manager (and much more) for K8s.
- Enable and configure the `ingress` addon for Minikube
- Enable and configure the `ingress-dns` addon for Minikube, with the related `NetworkManager` settings (more on that later)
- Enable and configure the `registry` addon for Minikube
- Starts a Docker container on your machine which acts like a proxy between Minikube and your local Docker engine.

For more details, read the next chapter of this document.

## <a id="manual-install"></a> 2. Manual Install

### <a id="docker"></a> 2.1. Install and configure Docker

Install the Docker package

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

### <a id="hypervisor"></a> 2.2. Install the KVM Hypervisor

Since Minikube creates a Virtual Machine, then installs a single node K8s cluster to it, you need to have a 
Hypervisor installed.

I choose the KVM to be me Hypervisor, in this section you can find the installation steps I took. It is possible
to use a different Hypervisor, but this document does not contain any information on other Hypervisors.

First, check if the virtualization is enabled on your system:

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
sudo cp ansible/roles/kvm-hypervisor/templates/libvirtd.conf /etc/libvirt/libvirtd.conf
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

### <a id="minikube"></a> 2.3. Install Minikube

First, you should install `kubectl`, which is a command line tool for interacting with your K8s cluster.

On ArchLinux, the kubectl is available in the repositories, so install it with the following command:

```bash
sudo pacman -S kubectl
```

Ensure that the version you installed is up to date:

```bash
kubectl version --client
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.3", GitCommit:"c92036820499fedefec0f847e2054d824aea6cd1", GitTreeState:"archive", BuildDate:"2021-10-28T06:55:39Z", GoVersion:"go1.17.2", Compiler:"gc", Platform:"linux/amd64"}
```

Now continue with the minikube installation. The `minikube` package is also available in the repositories.
To install it, execute the following command:

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
minikube start
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

If your output is similar to this, then you've successfully installed a local kubernetes environment on your machine using minikube.

### <a id="helm"></a> 2.4. Install HELM Package Manager

Helm is the package manager for kubernetes. To install it, you have to download latest release of the Helm client. On arch linux, Helm is avaialable in the pacman respository:

```bash
sudo pacman -S helm
```

Once you have installed Helm, you can add a chart repository.

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories
```

Once this is installed, you will be able to list the charts you can install:

```bash
$ helm search repo bitnami
NAME                                            CHART VERSION   APP VERSION     DESCRIPTION                                       
bitnami/bitnami-common                          0.0.9           0.0.9           DEPRECATED Chart with custom templates used in ...
bitnami/airflow                                 11.1.7          2.2.1           Apache Airflow is a platform to programmaticall...
bitnami/apache                                  8.9.1           2.4.51          Chart for Apache HTTP Server 
```

To install an example chart, you can run the `helm install` command. Helm has several ways to find and install a chart, but the easiest is to use the `bitnami` charts.

```bash
$ helm repo update
$ helm install bitnami/mysql --generate-name
NAME: mysql-1612624192
LAST DEPLOYED: Sat Feb  6 16:09:56 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES: ...
```

In this example, the `bitnami/mysql` chart was released.


```bash
** Please be patient while the chart is being deployed **

Tip:

  Watch the deployment status using the command: kubectl get pods -w --namespace default

Services:

  echo Primary: mysql-1636282288.default.svc.cluster.local:3306

Execute the following to get the administrator credentials:

  echo Username: root
  MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default mysql-1636282288 -o jsonpath="{.data.mysql-root-password}" | base64 --decode)

To connect to your database:

  1. Run a pod that you can use as a client:

      kubectl run mysql-1636282288-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mysql:8.0.27-debian-10-r8 --namespace default --command -- bash

  2. To connect to primary service (read/write):

      mysql -h mysql-1636282288.default.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"
```

### <a id="ingress"></a> 2.5. Enable the Ingress addon for Minikube

An Ingress is an API object that defines rules which allow external access to services in a cluster. An Ingress controller fulfills the rules set in the Ingress.

Enabling and configuring this addon is really easy, you just have to execute the following command:

```bash
$ minikube addons enable ingress
```

You can watch the creation of the Pods with the following command:

```bash
$ kubectl get pods -n ingress-nginx -w
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create--1-5j56w     0/1     Completed   0          29m
ingress-nginx-admission-patch--1-gxx6v      0/1     Completed   1          29m
ingress-nginx-controller-5f66978484-pg54f   1/1     Running     0          29m
```

Once you have the `ingress-nginx-controller` Pod running, you're done with this step.

### <a id="ingress-dns"></a> 2.6. Enable the Ingress-DNS addon for Minikube - [Original Docs](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/)

**Problem**

When running minikube locally you are highly likely to want to run your services on an ingress controller so that you don’t have to use minikube tunnel or NodePorts to access your services. While NodePort might be ok in a lot of circumstances in order to test some features an ingress is necessary. Ingress controllers are great because you can define your entire architecture in something like a helm chart and all your services will be available. There is only 1 problem. That is that your ingress controller works basically off of dns and while running minikube that means that your local dns names like myservice.test will have to resolve to $(minikube ip) not really a big deal except the only real way to do this is to add an entry for every service in your /etc/hosts file. This gets messy for obvious reasons. If you have a lot of services running that each have their own dns entry then you have to set those up manually. Even if you automate it you then need to rely on the host operating system storing configurations instead of storing them in your cluster. To make it worse it has to be constantly maintained and updated as services are added, remove, and renamed. I call it the /etc/hosts pollution problem.

**Solution**

What if you could just access your local services magically without having to edit your /etc/hosts file? Well now you can. This addon acts as a DNS service that runs inside your kubernetes cluster. All you have to do is install the service and add the $(minikube ip) as a DNS server on your host machine. Each time the dns service is queried an API call is made to the kubernetes master service for a list of all the ingresses. If a match is found for the name a response is given with an IP address as the $(minikube ip).

You can enable this addon by running the following command:

```bash
$ minikube addons enable ingress-dns
```

Since my system uses `NetworkManager` instead of `systemd-resolved`, I had to complete the following steps.

First I had to make sure that the `dnsmasq` is installed and enabled. It was installed but was not enabled.
To enable it, create a new file (if doesn't exists yet), with the following content:

```bash
# Content of /etc/NetworkManager/conf.d/dns.conf
[main]
dns=dnsmasq
```

Secondly, you have to configure your domain names for Minikube. To do so, create a new file with the following content:

```bash
# Content of /etc/NetworkManager/dnsmasq.d/minikube.cfg
server=/kube/192.168.39.23
```

Replace the `192.168.39.23` IP address with the IP address of your Minikube VM. You can find out the IP of your VM with this command:

```bash
minikube ip
```

To apply the changes you made, you have to reload the `NetworkManager` service. To do so, execute the following commands:

```bash
sudo nmcli general reload
sudo systemctl restart NetworkManager.service
```

With this configuration, the `dnsmasq` will resolve all Domain Names ending with `.kube` using the internal DNS server running inside
of Minikube.

This means, that from now on everytime you create an Ingress resource in Minikube, and the hostname of the Ingress resource is ends with
`.kube`, than the app will be available from your browser using its Domain Name, without having to use the `minikube service` command.

### <a id="registry"></a> 2.7 Enable the Registory addon for Minikube

Most probably you have a Docker engine running on your local computer (from where you're running the Minikube VM), and one in the
Minikube VM. The problem with that is when you build a Docker image on your computer, it is not avilable for the Minikube by default.

However, there are 2 possible solutions for this problem.

The first one does not require you to have your own Docker image registry up and running. Minikube provides a command for you, which 
points your shell to minikube's Docker daemon, all you have to do is to execute the following command:

```bash
eval $(minikube -p minikube docker-env)
```

The drawback of this solution is that every time you open a new shell you have to execute this command. You could add it to your `~/.bashrc`
file so it is executed automatically every time you start a new session.

The other solution which I choose is to have my own Docker registry, this one is fairly easy as well.

First you have to enable the `registry` addon for minikube by executing the following command:

```bash
$ minikube addons enable registry
```

This will set up a Docker image registry running inside the minikube VM. The registry runs in a docker container, and its exposes its port 5000
inside the VM.

In order to make this work, we have to somehow redirect port 5000 on local machine over to port 5000 on the minikube VM. The easiest way to do so
is to run a simple docker container as follows:

```bash
docker run \
    --rm \
    -it \
    -d \
    --network=host \
    alpine \
    ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"
```

Once this container with `socat` is running, it is possible to push Docker images to the minikube registry:

```bash
docker tag my/image localhost:5000/myimage
docker push local:5000/myimage
```

**Important:** After the image is pushed, refer to it by **`localhost:5000/myimage`** in kubectl specs.