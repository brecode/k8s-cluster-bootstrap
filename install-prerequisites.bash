#!/bin/bash

# Script should run as root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Exiting..." 
   exit 1
fi

# This script will: add keys, update and install pre-requisites 
echo "Updating Ubuntu..."
apt-get update
echo "Install os requirements"
apt-get install -y apt-transport-https \
                   apt-transport-https \
                   ca-certificates \
                   curl \
                   software-properties-common
                   
echo "Add Kubernetes & Docker repo..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
EOF

echo "Updating Ubuntu..."
apt-get update

echo "Installing Docker-CE..."
apt-get install -y docker-ce

systemctl stop docker
modprobe overlay
echo '{"storage-driver": "overlay2"}' > /etc/docker/daemon.json
rm -rf /var/lib/docker/*
systemctl start docker

echo "Installing Kubernetes Components..."
apt-get install -y kubelet kubectl kubeadm kubernetes-cni