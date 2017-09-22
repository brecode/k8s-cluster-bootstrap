#!/bin/bash
# Script should run as root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Exiting..." 
   exit 1
fi
set -e
echo "Exporting Kube Master IP and Kubeadm Token..."
echo "export KUBE_MASTER_IP=$(hostname -I | cut -f2 -d' ')" >> config/init.bash
echo "export KUBEADM_TOKEN=$(kubeadm token generate)" >> config/init.bash
source config/init.bash
echo "Starting kubernetes..."
kubeadm init --kubernetes-version=v1.7.6 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"
# Schedule Pods on master. 
kubectl taint nodes --all node-role.kubernetes.io/master-