#!/bin/bash

# Script should run as root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Exiting..." 
   exit 1
fi

# This script will also: add keys, update and install pre-requisites
echo Args passed: [[ $@ ]]
cat <<EOF >/etc/profile.d/envvar.sh
export http_proxy='#{http_proxy}'
export https_proxy='#{https_proxy}'
EOF
source /etc/profile.d/envvar.sh 
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
touch /var/run/contivshim.sock
sed -i '4 a Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false --container-runtime=remote --container-runtime-endpoint=/var/run/contivshim.sock --feature-gates=AllAlpha=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl restart kubelet

echo "Downloading Go"
curl --silent https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz > /tmp/go.tar.gz

echo "Extracting Go"
tar -xvzf /tmp/go.tar.gz --directory /home/vagrant >/dev/null 2>&1

echo "Setting Go environment variables"
mkdir /home/vagrant/gopath
chmod -R 777 /home/vagrant/gopath
echo 'export GOROOT="/home/vagrant/go"' >> /home/vagrant/.bashrc
echo 'export GOPATH="/home/vagrant/gopath"' >> /home/vagrant/.bashrc
echo 'export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"' >> /home/vagrant/.bashrc
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

echo 'All done!'

