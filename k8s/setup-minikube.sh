#!/usr/bin/env bash

# Install ansible if not present
which ansible > /dev/null
if [ $? -eq 1 ]; then
    sudo pacman -S --noconfirm ansible
fi

# Setup local K8s environment with Minikube
ansible-playbook ansible/playbooks/minikube.yaml --tags minikube

# Sometimes, Pods like storage-provisioner or kube-scheduler are not
# in completed state by the time we get to the configuration of Minikube
# addons. In such cases the addon installation will just timeout, and the
# whole environment must be recreated.
#
# Quick and dirty solution is to add some sleep before moving on to the
# configuration of the addons.
# 
# TODO: Add a wait condition here -> Watch the status of the required
# Pods in Minikube
sleep 10s

# Enable required Minikube addons
ansible-playbook ansible/playbooks/minikube.yaml --tags minikube-addons