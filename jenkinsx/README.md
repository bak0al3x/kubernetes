# Table of Contents

- [1. About Jenkins X](#about-jenkins)
- [2. Prerequisites](#prerequisites)
    - [2.1. `jx` install](#jx-install)
    - [2.1. Minikube installation and setup](#minikube)
- [3. Create a Git repository](#git-repo)
- [4. Jenkins X Ingress Configuration](#jx-ingress)
- [5. Install and setup Ngrok](#ngrok)
- [6. Install the Git Operator](#git-operator)
- [7. Enable Webhooks](#enable-webhooks)

# Installation notes of Jenkins X on Minikube

At first, I've tried to follow th [offical installation document](https://jenkins-x.io/v3/admin/platforms/minikube/), but it did not work properly for me.

However after some days of researching I found a wokring solution, here are the steps I took for the installation.

# <a id="about-jenkins"></a> 1. About Jenkins X

Jenkins X is much like a serverless Jenkins, it takes care about the whole CI/CD process.
It is built from the following components:

- `Lightouse` for webhooks and ChatOps
- `Tekton` for pipeline definition
- `Nexus` for storing artifacts
- `ChartMuseum` is much like an artifactory but for Helm charts
- `Docker Registry` which is an in cluster registry for storing your built Docker images.

All of these are managed with the `jx` command line tool. Creating a Cloud Native development environment on Kubernetes is just as easy as executing the following command:

```bash
jx create
```

At least, the documentation says so. When using public cloud providers, most probably this is the case, but my experience on Minikube was terrible with Jenkins X.

# <a id="prerequisites"></a> 2. Prerequisites

## <a id="jx-install"></a> 2.1. `jx` installation

`jx` is the modular command line CLI for Jenkins X 3.x. To install it you have to download the binary and move it to a location somewhere in your `$PATH`.

```bash
curl -L https://github.com/jenkins-x/jx/releases/download/v3.2.217/jx-linux-amd64.tar.gz | tar xzv
chmod +x jx 
sudo mv jx /usr/local/bin
```

After this step, you can verify your installation via:

```bash
$ jx version
version: 3.2.216
```

## <a id="minikube"></a> 2.2. Minikube installation and setup

You need to have a working installation of `minikube` with the `ingress` addon enabled, and working.
This step is not part of this document, but the steps can be found in the [k8s/README.md](../k8s/README.md) file.

# <a id="git-repo"></a> 3. Create a Git repository

In this step, you have to create a repository based on the [jx3-gitops-repository](https://github.com/jx3-gitops-repositories/jx3-minikube/generate) template.
All you have to do is to click on this linkn and create the repo for yourself.

**Note: To make that link work, you have to be logged in to your GitHub account**.

# <a id="jx-ingress"></a> 4. Jenkins X Ingress Configuration

First step is to clone your repository you created in the previous chapter.

After you've done with that part, you can configure the `ingress.domain` to point to your `$(minikube ip).nip.io`:

```bash
export DOMAIN="$(minikube ip).nip.io"
jx gitops requirements edit --domain $DOMAIN
```

Now the `jx-requirements.yaml` file should now be configured with the value of `$DOMAIN`. To make this work, your working directory must be the root of the repository you cloned
previously.

# <a id="ngrok"></a> 5. Install and setup Ngrok

First you have to go the the website of [Ngrok](https://ngrok.com/). Here you have to create a new account, if you don't have one yet.
The creation of a new account is required, as this is the only way to obtain an `authtoken`. Without the this token, I couldn't make
the installation work.

Now time to install the ngrok package itself, to do so you have to download a binary, and move it to a location which is present in your `$PATH`.

```bash
 curl -L https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux.zip 
chmod +x ngrok
sudo mv ngrok /usr/local/bin/
```

Once you've done this, log in to the ngrok's website, and go to the [Setup & Installation](https://dashboard.ngrok.com/get-started/setup) section.
Here you'll find your `authtoken` which we have to provide for ngok to connect to your account.

Execute the following command to add your token to ngrok:

```bash
ngrok authtoken YOUR_TOKEN_GOES_HERE
```

Ngrok stores this configuration (at least on linux) under the following directory: `~/.ngrok2/ngrok.yaml`. At this point this file should contain only your `authtoken`.

Now you need to start an HTTP tunnel on your machine on port 8080. Ngrok is a software for doing so. Once you start a tunnel, you will receive a randomly generated
domain name, which point to your machine, and it can be accessed from the public internet.

Because of this, you may need to configure your own router to enable to forward this port to the proper machine, and also open the required port on your router's firewall.

To start a tunnel, execute this command:

```bash
ngrok http 8080
```

This will produce an output something like this:

```bash
Session Status                online                                                                                                                                                                                                                                  
Account                       Alex Bako (Plan: Free)                                                                                                                                                                                                                  
Version                       2.3.40                                                                                                                                                                                                                                  
Region                        Europe (eu)                                                                                                                                                                                                                             
Web Interface                 http://127.0.0.1:4040                                                                                                                                                                                                                   
Forwarding                    http://1709-89-132-120-224.eu.ngrok.io -> http://localhost:8080                                                                                                                                                                         
Forwarding                    https://1709-89-132-120-224.eu.ngrok.io -> http://localhost:8080 
```

You need to keep this terminal tab open to make ngrok work.

Now copy your personal ngrok domain in the form of `abcdef1234.ngrok.io` into the `charts/jenkins-x/jxboot-helmfile-resources/values.yaml` file in the 
`ingress.customHosts.hosts` resource, so that your file looks like this:

```yaml
ingress:
  customHosts:
    hook: "1709-89-132-120-224.eu.ngrok.io"

kaniko:
  flags: "--insecure"
```

Now commit your changes and push them to the remote repository.

# <a id="git-operator"></a> 6. Install the Git Operator

First, you have to create a new Peronal Access Token on github. During the Git Operator installation, the jx will fetch and push changed to your remote repository.
This token is required for the JX to be able to do that.

You can create a new [Personal Access Token](https://github.com/settings/tokens/new?scopes=repo,read:user,read:org,user:email,admin:repo_hook,write:packages,read:packages,write:discussion,workflow) with the provided link.

**Note: You have to save your personal access token somewhere, as you can view it only one time. If you forget to do this, you have to generate a new token for yourself.**

With only this token I could not complete the installation, many times I got an `HTTP 403` error. Although I am not completely sure that this is required, but I did that.
Since the installation guides explicitly wants us to use HTTP connection for the remote repository (instead of SSH), I've created a new GPG key, and added it to my GitHub account.

GitHub has great documentations on this topic:
- [How to generate a new GPG token](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key)
- [How to add a GPG token to your account](https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-new-gpg-key-to-your-github-account)

After I've done all this, I wanted to continue the installation based on the offical documentation, however it failed all the time. After I've spent some time reasearching what causes
this issue, I found a [really similar issue on GitHub](https://github.com/jenkins-x/jx/issues/7942#issuecomment-915955471), so I've completed the installation with HELM as suggested in
that comment.

First, add the `jx3` HELM repository:

```bash
helm repo add jx3 https://jenkins-x-charts.github.io/repo
```

Then install the `jx-git-operator` using the Helm package:

```bash
GIT_URL="https://github.com/bak0al3x/jx3-minikube.git"
GIT_USER="bak0al3x"
GIT_TOKEN="YOUR_PERSONAL_ACCESS_TOKEN"

helm upgrade --install \
    --set url=$GIT_URL \
    --set username=$GIT_USER \
    --set password=$GIT_TOKEN \
    -n jx-git-operator \
    --create-namespace jxgo \
    jx3/jx-git-operator
```

You can check the logs of the installation with the following command:

```bash
jx admin logs
```

# <a id="enable-webhooks"></a> 7. Enable Webhooks

Once the installation completed, first switch to the `jx` namespace:

```bash
jx ns jx
```

And then, run the following command, to enable `webhooks` via `ngrok`:

```bash
kubectl port-forward svc/hook 8080:80
```

