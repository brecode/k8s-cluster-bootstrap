#!/bin/bash
# Script should run as root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Exiting..." 
   exit 1
fi
# Kubeadm join expects kube_master_ip and kubeadm_token
set -e
source config/init.sh
kubeadm join --token "${KUBEADM_TOKEN}"  "${KUBE_MASTER_IP}":6443
