# K8s Bootstraping with Kubeadm

The repository provides a bare-metal (using scripts) and VM (using Vagrant) solution to 
set up Kubernetes clusters, leveraging `kubeadm`

## Pre-requisites

The scripts will provide all the pre-requisites needed to run a kubernetes cluster. For the bare metal option, 
you will need two, or more, nodes (metal or VM). For the vagrant option just specify the number of the nodes. 
*Warning* Set the v.memory and v.vcpus parameters according to your system resources. 
**Tested on Ubuntu 16.04 only**

## Networking Issues

To download docker images the cluster must have outbound internet connection. Running behind a proxy 
results in `kubeadm init` command to fail. In vagrant this is resolved by not passing the `http_proxy/https_proxy`
ENV variables. 
*TODO: A solution is being investigated in the bare metal solution* 

## Setting up the K8s Cluster - Two options available

### Option #1 - Bare metal solution

Follow the instructions to setup a K8s cluster either on physical nodes or on VMs running on physical nodes. 

#### Setting up the K8s Master Node

1. Clone this git repository into your master node
   `git clone https://github.com/brecode/k8s-cluster-bootstrap.git`

2. Install the pre-requisites on the master. This script will install docker-ce/kubelet/kubeadm/kubernetes-cni packages
   ```bash
   cd k8s-cluster-bootstrap
   sudo ./install-prerequisites.bash
   ```

3. Make sure init.bash under `config` is empty. This is the file where the previous script stores 
KUBE_MASTER_IP and KUBEADM_TOKEN variables.
   
   a. `KUBE_MASTER_IP` - is the IP of the kubernetes master node that listens for connections from the 
   other nodes
   b. `KUBEADM_TOKEN` - token generated from `kubeadm token generate` command. This token will later be used to authenticate the nodes that will join the cluster. *Do not share the token with un-authorized users*
    
4. Setup the master - run this as root too!
   ``` bash
   sudo ./bootstrap-master.bash
   ```
   
  Installs the follwoing:
   
   a. The components that K8s Master should have (apiserver,
      scheduler, controller-manager and etcd)
    b. Calico networking 
   c. Copy `/etc/kubernetes/admin.conf` to `~/.kube/config` - Connection and credential information to connect to the cluster are stored here as well as networking schemas and information from Calico.  K8s master node has also been marked as schedulable so that pods can be deployed on the master node. If you don't want more nodes (workers) you can stop here. If you need a bigger cluster proceed to the `Setting up a worker node` section

#### Setting up a worker node

1. Clone this git repository on to your worker node
   `git clone https://github.com/brecode/k8s-cluster-bootstrap.git`
   
2. Install the pre-requisites on the worker node.
   ```bash
    cd k8s-cluster-bootstrap
   sudo ./install-prerequisites.bash`
   ```

3. Copy `data/config.bash` from the master node under this directory. This file has the information needed to join the K8s cluster. 
   
4. Setup the node to join the cluster. 
   ```bash
   ./bootstrap-worker.bash
   ```

#### Test the K8s cluster
To test the cluster simply issue the following commands: 

   a. On the master, run `kubectl get node` - you should be able to see all the nodes that have joined the cluster. 

   b. Run `kubectl get pod -o wide`. This should show all the containers that have been deployed to run a k8s cluster. Pods should be: 
   calico-etcd
   calico-node
   calico-policy-controller
   etcd-k8s-master
   kube-api-server
   kube-controller-manager
   kube-dns
   kube-proxy
   kube-scheduler

### Option #1 - Vagrant VMs

Edit K8S_NODES (range 0..n) to specify the cluster size. Then simply run: 
```bash
  ./vagrant-up.sh
```

This will create a cluster of one K8s master and as many workers as you specified on the K8S_NODES variable. 
To access the VMs issue:
```bash 
vagrant ssh k8s-master
vagrant ssh k8s-worker1
...
vagrant ssh k8s-workern
```

To cleanup and destroy the VMs run:
```bash 
./vagrant-cleanup.sh
```