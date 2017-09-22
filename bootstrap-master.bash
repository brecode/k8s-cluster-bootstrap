#!/bin/bash
set -e

source config/init.bash

kubeadm init --kubernetes-version=v1.7.6 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"

# By now the master node should be ready!
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant -R /home/vagrant/.kube

# Install Calico networking
kubectl apply -f config/calico.yaml
