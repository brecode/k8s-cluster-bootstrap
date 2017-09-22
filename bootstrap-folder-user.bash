#!/bin/bash

# Create folder to store kubernetes and network configuration
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) -R ~/.kube

# Install Calico networking
echo "Installing Pod Network..."
kubectl apply -f config/calico.yaml