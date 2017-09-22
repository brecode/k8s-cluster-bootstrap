#!/bin/bash
# Script should run as root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Exiting..." 
   exit 1
fi
if [ -z "$1" ]
  then
    echo "Pass the username as an argument. Exiting..."
    exit 1
fi
set -e
# Create token and export it with kube master IP
echo "Exporting Kube Master IP and Kubeadm Token..."
echo "export KUBE_MASTER_IP=$(hostname -I | cut -f2 -d' ')" >> config/init.bash
echo "export KUBEADM_TOKEN=$(kubeadm token generate)" >> config/init.bash
source config/init.bash
# Install Kubernetes
echo "Starting kubernetes..."
kubeadm init --kubernetes-version=v1.7.6 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"

# Create folder to store kubernetes and network configuration
mkdir -p /home/$1/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/$1/.kube/config
sudo chown $1:$1 -R /home/$1/.kube

# Install Calico networking
echo "Installing Pod Network..."
sudo -u $1 kubectl apply -f config/calico.yaml

# Schedule Pods on master. 
kubectl taint nodes --all node-role.kubernetes.io/master-