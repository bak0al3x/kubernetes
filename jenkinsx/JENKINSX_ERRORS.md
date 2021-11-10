# Jenkins X Installation Errors

I've tried to installed Jenkins X on my local Minikube environment, with no success.

## 1. Installation based on the [Jenkins X Helm Charts](https://github.com/jenkins-x/jenkins-x-platform)

## 1.1. Installation of the JX tool

This is a tool for interacting with Jenkins X. For installation, `jx` delegates to `Helm` for installs, upgrades and uninstall operations.

Install `jx` cli tool with the following command:

```bash
curl -L https://github.com/jenkins-x/jx/releases/download/v3.2.216/jx-linux-amd64.tar.gz | tar xzv
chmod +x jx 
sudo mv jx /usr/local/bin
```

Then verify your installation

```bash
$ jx version
version: 3.2.216
```

## 1.2. Setup Local Development

For local development you could install Jenkins X with Minikube.

To install it, execute the following commands:

```bash
git clone https://github.com/jenkins-x/cloud-environments && cd cloud-environments
jx create cluster minikube --local-cloud-environment=true
```

But when I try to execute these commands, I got the following errors:

```bash
$ jx create cluster minikube --local-cloud-environment=true

Error: unknown flag: --local-cloud-environment


Available Commands:
  create project alias for: jx project
  create pullrequest alias for: jx pullrequest
  create quickstart alias for: jx quickstart
  create spring alias for: jx spring

Usage:
  jx create TYPE [flags] [options]
Use "jx <command> --help" for more information about a given command.
Use "jx create options" for a list of global command-line options (applies to all commands).
```

Here I suspected that there may be some issues with the different versions of the `jx` cli tool, and the `jenkins-x` versions.
This guide is for the `2.0.2412` version of the `Jenkins X`, but I was using the latest `jx` cli tool, which is (as of writing this document)
`3.2.216`.

Okay so here I downgraded to a previous version. I've tried to match the major and minor versions of the `jx` with the `2.0.2412` release.
The closes I found is the [2.0.1286](https://github.com/jenkins-x/jx/releases/tag/v2.0.1286) release. I did the downgrade, but I still get the `unknown flag` error, however
the error message is slightly different, but still not working as expected.

```bash
curl -L https://github.com/jenkins-x/jx/releases/download/v2.0.1286/jx-linux-amd64.tar.gz | tar xzv 
sudo mv jx /usr/local/bin
```

Now, when I execute the `jx version` command, it complains about the Helm version:


```bash
$ jx version
WARNING: Failed to retrieve team settings: failed to setup the dev environment for namespace 'default': the server could not find the requested resource (post environments.jenkins.io) - falling back to default settings...
FATAL: Your current helm version v3 is not supported. Please downgrade to helm v2.
```

As for now, I wouldn't go with the Helm downgrade, I'll try to deploy Jenkins X with the latest version then.

Just to be on the safe side I've checked if everything is working fine:

```bash
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.39.135:8443
CoreDNS is running at https://192.168.39.135:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

$ minikube addons list | grep enabled
| default-storageclass        | minikube | enabled ✅   | kubernetes            |
| ingress                     | minikube | enabled ✅   | unknown (third-party) |
| ingress-dns                 | minikube | enabled ✅   | unknown (third-party) |
| registry                    | minikube | enabled ✅   | google                |
| storage-provisioner         | minikube | enabled ✅   | kubernetes            |
```

Seems like everything is working fine. Now I'll deploy an example app on minikube just to be 100% sure that everything is working as expected.

```bash
$ docker push localhost:5000/hello-kube-react
Using default tag: latest
The push refers to repository [localhost:5000/hello-kube-react]
6dcad604c341: Pushed 
320a271c234b: Pushed 
6db1b580ba1a: Pushed 
add0bef2945b: Pushed 
1212be9e0334: Pushed 
a1920ef522ec: Pushed 
f1dd685eb59e: Pushed 
latest: digest: sha256:3e7bc2c4534832fae8499d6be5949f05602080310ae9bda8683dd9541a5788f7 size: 1778

$ helm upgrade --install hello-kube-react app/frontend-helm
Release "hello-kube-react" does not exist. Installing it now.
NAME: hello-kube-react
LAST DEPLOYED: Mon Nov  8 20:36:42 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

$ kubectl get pods 
NAME                           READY   STATUS    RESTARTS   AGE
hello-react-6f8fc797c6-57d9s   1/1     Running   0          25s
hello-react-6f8fc797c6-vp9hl   1/1     Running   0          25s

$ kubectl get ingress 
NAME          CLASS   HOSTS              ADDRESS     PORTS   AGE
hello-react   nginx   hello-react.kube   localhost   80      31s

$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
hello-kube-react        default         1               2021-11-08 20:36:42.020706963 +0100 CET deployed        hello-kube-react-0.1.0  0.0.1 

$ curl -I hello-react.kube
HTTP/1.1 200 OK
Date: Mon, 08 Nov 2021 19:38:02 GMT
Content-Type: text/html
Content-Length: 3018
Connection: keep-alive
Last-Modified: Sun, 07 Nov 2021 16:35:53 GMT
ETag: "61880069-bca"
Accept-Ranges: bytes
```

Yes, everything is working as expected.


## 2. Installation based on the [Jenkins X Admin Guide](https://jenkins-x.io/v3/admin/platforms/minikube/)

### 2.1. Prerequisites

First, we have to install the latest version of the `jx` cli tool. To do so, execute the following command:

```bash
curl -L https://github.com/jenkins-x/jx/releases/download/v3.2.216/jx-linux-amd64.tar.gz | tar xzv
chmod +x jx 
sudo mv jx /usr/local/bin
```

Then again, verify your install with the following command:

```bash
$ jx version
version: 3.2.216
```

After that, you have to have a working `minikube` installation, with `ingress` enabled, I already have this:

```bash
$ minikube addons list | grep enabled
| default-storageclass        | minikube | enabled ✅   | kubernetes            |
| ingress                     | minikube | enabled ✅   | unknown (third-party) |
| ingress-dns                 | minikube | enabled ✅   | unknown (third-party) |
| registry                    | minikube | enabled ✅   | google                |
| storage-provisioner         | minikube | enabled ✅   | kubernetes            |
```

Since everything was working as expected at the end of the previous chapter, I won't include all the same shell outputs in here.

### 2.2. Setup

#### 2.2.1. Create the Cluster Git Repository

Next step is to generate a Git Repository based on the [jx3-minikube-template](https://github.com/jx3-gitops-repositories/jx3-minikube/generate). Here is the repository I've generated: [bak0al3x/jx3-minikube](https://github.com/bak0al3x/jx3-minikube).

Now, I have to clone this repository via HTTPS (the tutorial says so).

```bash
$ git clone https://github.com/bak0al3x/jx3-minikube.git
Cloning into 'jx3-minikube'...
remote: Enumerating objects: 323, done.
remote: Counting objects: 100% (323/323), done.
remote: Compressing objects: 100% (245/245), done.
remote: Total 323 (delta 28), reused 231 (delta 11), pack-reused 0
Receiving objects: 100% (323/323), 121.43 KiB | 1.26 MiB/s, done.
Resolving deltas: 100% (28/28), done.
```

#### 2.2.2. Configure the `ingress.domain`

And then I have to configure the `ingress.domain` to point to `$(minikube ip).ntp.io`:

```bash
$ cd jx3-minikube/
$ export DOMAIN="$(minikube ip).nip.io"
$ jx gitops requirements edit --domain $DOMAIN
saved file: /tmp/jx3-minikube/jx-requirements.yml
```

#### 2.2.3. Setup and Configure Ngrok

Next step is to install and configure `ngrok`.

Installation:

```bash
$ cd /tmp
$ mkdir ngrok && cd ngrok
$ curl https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok-stable-linux-amd64.zip
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 13.1M  100 13.1M    0     0  8319k      0  0:00:01  0:00:01 --:--:-- 8317k
$ unzip ngrok-stable-linux-amd64.zip 
Archive:  ngrok-stable-linux-amd64.zip
  inflating: ngrok                   
$ sudo mv ngrok /usr/local/bin/
$ cd ..
$ rm -rf ngrok/
$ ngrok --version
ngrok version 2.3.40
```

Seems like `ngrok` needs a registration for me, to use it properly. After registration I have an auth token, I have to connect `ngrok` to my account:
(I won't include my token in here :) )

```bash
$ ngrok authtoken TOKEN
Authtoken saved to configuration file: /home/bakoa/.ngrok2/ngrok.yml
```

#### 2.2.4. Configure the customHosts

Now I have to fire up a webhook tunnel using ngrok:

```bash
ngrok http 8080

ngrok by @inconshreveable                                                                                                                                                                                                                                            (Ctrl+C to quit)
                                                                                                                                                                                                                                                                                     
Session Status                online                                                                                                                                                                                                                                                 
Account                       Alex Bako (Plan: Free)                                                                                                                                                                                                                                 
Version                       2.3.40                                                                                                                                                                                                                                                 
Region                        United States (us)                                                                                                                                                                                                                                     
Web Interface                 http://127.0.0.1:4040                                                                                                                                                                                                                                  
Forwarding                    http://d039-89-132-120-224.ngrok.io -> http://localhost:8080                                                                                                                                                                                           
Forwarding                    https://d039-89-132-120-224.ngrok.io -> http://localhost:8080                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                     
Connections                   ttl     opn     rt1     rt5     p50     p90                                                                                                                                                                                                            
                              0       0       0.00    0.00    0.00    0.00   
```

From here, I need my personal ngrok domain, and I have to add it to the `values.yaml` file:

```bash
$ cat charts/jenkins-x/jxboot-helmfile-resources/values.yaml 

ingress:
  # allows you to specify custom hosts
  customHosts:
    # specify your ngrok custom domain here
    # such as
    #    hook: "myuniqueid.ngrok.io
    # so that webhooks from, say, github.com, will work to your local laptop
    hook: "d039-89-132-120-224.ngrok.io"

kaniko:
  # lets support insecure docker registries so that we
  # can use the local docker-registry chart
  flags: "--insecure"
  ```

Then I have to commit and push all the changes I made in the repostiroy.

```bash
$ git add .
$ git commit -a -m 'fix: Configuration for local minikube environment'
[main ec196b5] fix: Configuration for local minikube environment
 2 files changed, 4 insertions(+), 4 deletions(-)
$ git push origin main
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 16 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (7/7), 617 bytes | 617.00 KiB/s, done.
Total 7 (delta 3), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
To https://github.com/bak0al3x/jx3-minikube.git
   a855ef4..ec196b5  main -> main
```

### 2.3. Install the Git operator

First you need to generate a personal access token on GitHub. Once you've done that, you can proceed with the following steps. Make sure that 
you copy your token, since it is viewable only once. There is no way to view a token after generation, the only option is that case is to regenerate the token.

Installing the operator:

```bash
jx admin operator --url=https://github.com/bak0al3x/jx3-minikube.git --username bak0al3x --token TOKEN
```

But here I got an error message as well:

```bash
error validating "config-root/customresourcedefinitions/jx/jenkins-x-crds/environments.jenkins.io-crd.yaml": error validating data: [ValidationError(CustomResourceDefinition.spec): unknown field "additionalPrinterColumns" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "validation" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "version" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec]; if you choose to ignore these errors, turn validation off with --validate=false
error validating "config-root/customresourcedefinitions/jx/jenkins-x-crds/pipelineactivities.jenkins.io-crd.yaml": error validating data: [ValidationError(CustomResourceDefinition.spec): unknown field "additionalPrinterColumns" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "validation" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "version" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec]; if you choose to ignore these errors, turn validation off with --validate=false
error validating "config-root/customresourcedefinitions/jx/jenkins-x-crds/releases.jenkins.io-crd.yaml": error validating data: [ValidationError(CustomResourceDefinition.spec): unknown field "additionalPrinterColumns" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "validation" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "version" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec]; if you choose to ignore these errors, turn validation off with --validate=false
error validating "config-root/customresourcedefinitions/jx/jenkins-x-crds/sourcerepositories.jenkins.io-crd.yaml": error validating data: [ValidationError(CustomResourceDefinition.spec): unknown field "additionalPrinterColumns" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "validation" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec, ValidationError(CustomResourceDefinition.spec): unknown field "version" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec]; if you choose to ignore these errors, turn validation off with --validate=false
make[1]: Leaving directory '/workspace/source'
make[1]: *** [versionStream/src/Makefile.mk:288: kubectl-apply] Error 1
error: failed to regenerate: failed to regenerate phase 1: failed to run 'make regen-phase-1' command in directory '.', output: ''
make: *** [versionStream/src/Makefile.mk:242: regen-check] Error 1
boot Job pod jx-boot-4deee32e-327e-4d46-bba8-10ff9b93bb7b--1-g2798 has Failed
boot Job jx-boot-4deee32e-327e-4d46-bba8-10ff9b93bb7b has Failed
error: failed to tail the Jenkins X boot Job pods: job jx-boot-4deee32e-327e-4d46-bba8-10ff9b93bb7b failed
```

After like an hour of googling I haven't found any relavant threads. When I open the logs of that faulty Pod, I can see the same messages there.