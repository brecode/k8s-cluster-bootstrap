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

# --------------------------------------------------------
# ---> Create token and export it with kube master IP <---
# --------------------------------------------------------
echo "Exporting Kube Master IP and Kubeadm Token..."
echo "export KUBE_MASTER_IP=$(hostname -I | cut -f2 -d' ')" >> /vagrant/config/init.sh
echo "export KUBEADM_TOKEN=$(kubeadm token generate)" >> /vagrant/config/init.sh
source /vagrant/config/init.sh

# --------------------------------------------------------
# ------------> Download or build ContivShim <------------
# --------------------------------------------------------
echo "Downloading Contivshim"
touch /tmp/contivshim.log
tar -xvzf /vagrant/contivshim.tar.gz --directory /home/vagrant >/dev/null 2>&1
# instructions on how to build - coming soon...

# --------------------------------------------------------
# --------------> Start ETCDv3 Instance <-----------------
# --------------------------------------------------------
docker run -d -p 25552:25552 --rm \
    quay.io/coreos/etcd:v3.2.0 /usr/local/bin/etcd \
    -advertise-client-urls http://0.0.0.0:25552 \
    -listen-client-urls http://0.0.0.0:25552

# --------------------------------------------------------
# ----------------> Start GRPC Server <-------------------
# --------------------------------------------------------
echo "Starting GRPC Server"
nohup /home/vagrant/contiv-cri --v=2 0<&- &> /tmp/contivshim.log &

# --------------------------------------------------------
# --------------> Kubeadm & Networking <------------------
# --------------------------------------------------------
kubeadm reset
kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"
echo "Create folder to store kubernetes and network configuration"
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant -R /home/vagrant/.kube

echo "Installing Calico networking as user"
sudo -u vagrant -H bash << EOF

echo "Installing Pod Network..."
kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

echo "Schedule Pods on master"
kubectl taint nodes --all node-role.kubernetes.io/master-
EOF