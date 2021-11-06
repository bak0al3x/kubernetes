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

(Optional) Enable the startup of the `docker` service at startup

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