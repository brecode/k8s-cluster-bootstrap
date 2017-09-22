#!/bin/bash
# Kubeadm join expects kube_master_ip and kubeadm_token
set -e

source config/init.bash

kubeadm join --token "${KUBEADM_TOKEN}"  "${KUBE_MASTER_IP}":6443
