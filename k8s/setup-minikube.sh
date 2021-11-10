#!/usr/bin/env bash

# Install ansible if not present
which ansible > /dev/null
if [ $? -eq 1 ]; then
    sudo pacman -S --noconfirm ansible
fi

# Setup local K8s environment with Minikube
ansible-playbook ansible/playbooks/minikube.yaml --tags minikube