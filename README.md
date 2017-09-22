# K8s Bootstraping with Kubeadm

The repository provides a bare-metal (using scripts) and VM (using Vagrant) solution to 
set up Kubernetes clusters, leveraging `kubeadm`

## Pre-requisites

The scripts will provide all the pre-requisites needed to run a kubernetes cluster. For the bare metal option, 
you will need one, or more, nodes (metal or VMs). For the vagrant option just specify the number of the nodes. 
*Warning* Set the v.memory and v.vcpus parameters according to your system resources. 
**Tested on Ubuntu 16.04 only**

## Networking Issues

To download docker images the cluster must have outbound internet connection. Running behind a proxy 
results in `kubeadm init` command to fail. In vagrant this is resolved by not passing the `http_proxy/https_proxy`
ENV variables. 
*TODO: A solution is being investigated in the bare metal solution* 

## Setting up the K8s Cluster - Two options available

### Option #1 - Bare metal solution

Follow the instructions to setup a K8s cluster either on physical nodes or VMs. Minimum requirement is to setup at least the K8s master node. 

#### Setting up the K8s Master Node

  1. Clone this git repository into your master node
  ```bash
  git clone https://github.com/brecode/k8s-cluster-bootstrap.git
  ```

  2. Install the pre-requisites on the master. This script will install docker-ce/kubelet/kubeadm/kubernetes-cni packages
  ```bash
  cd k8s-cluster-bootstrap
  sudo ./install-prerequisites.sh
  ```

  3. Make sure init.sh under `config` is empty. This is the file where the previous script stores 
  KUBE_MASTER_IP and KUBEADM_TOKEN variables.
  + `KUBE_MASTER_IP` - is the IP of the kubernetes master node that listens for connections from the other nodes
  + `KUBEADM_TOKEN` - token generated from `kubeadm token generate` command. This token will later be used to authenticate the nodes that will join the cluster. *Do not share the token with un-authorized users*

  4. Bootstrap the master (need to run as root) and pass the node's username as an argument
  ```bash
  sudo ./bootstrap-master.sh username
  ```

  5. Installs the follwoing:

+ The components that K8s Master should have (apiserver, scheduler, controller-manager and etcd)
+ Calico networking 
+ Copies `/etc/kubernetes/admin.conf` to `~/.kube/config` - Connection and credential information to connect to the cluster are stored here, as well as networking schemas and information from Calico.  K8s master node has also been marked as schedulable, so that pods can be deployed. If there is no need for more nodes (workers) stop here. If a bigger cluster is needed proceed to the next section.

#### Setting up a worker node

  1. Clone this git repository on to your worker node
  ```bash
  git clone https://github.com/brecode/k8s-cluster-bootstrap.git
  ```

  2. Install the pre-requisites on the worker node.
  ```bash
  cd k8s-cluster-bootstrap
  sudo ./install-prerequisites.sh
  ```

  3. Copy the contents of `data/config.sh` from the master node under this directory. The file hold the information needed to join the K8s cluster. 

  4. Setup the node to join the cluster. 
  ```bash
  ./bootstrap-worker.sh
  ```

#### Test the K8s cluster
To test the cluster simply issue the following commands: 

+ On the master, run `kubectl get node` - you should be able to see all the nodes that have joined the cluster. 

+ Run `kubectl get pod -n kube-system -o wide`. The command should show all the containers that need to be deployed to run a k8s cluster. 
Example:
```
calico-etcd
calico-node
calico-policy-controller
etcd-k8s-master
kube-api-server
kube-controller-manager
kube-dns
kube-proxy
kube-scheduler
```

### Option #2 - Vagrant VMs

Follow the instructions to setup a K8s cluster using Vagrant and Virtualbox.  

#### Using Vagrant and Vagrantfile 
To specify the cluster size, edit `vagrant-up.sh` K8S_NODES (range 0..n, where 0 installs only the K8s master) value. Then simply run: 
```bash
./vagrant-up.sh
```

This will create a cluster of one K8s master and as many workers (nodes) as you specified on the K8S_NODES variable. 
To access the VMs issue:
```bash 
vagrant ssh k8s-master
vagrant ssh k8s-worker1
...
vagrant ssh k8s-workern
```

To cleanup the environment and destroy the VMs run:
```bash 
./vagrant-cleanup.sh
```

#### Test the K8s cluster
Same as for option 1 to test the cluster simply issue the following commands: 

+ On the master, run `kubectl get node` - you should be able to see all the nodes that have joined the cluster. 

+ Run `kubectl get pod -n kube-system -o wide`. The command should show all the containers that need to be deployed to run a k8s cluster. 
Example:
```
calico-etcd
calico-node
calico-policy-controller
etcd-k8s-master
kube-api-server
kube-controller-manager
kube-dns
kube-proxy
kube-scheduler
```

### TROUBLESHOOTING 

From `https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/` If you are using VirtualBox (directly or via Vagrant), you will need to ensure that hostname -i returns a routable IP address (i.e. one on the second network interface, not the first one). By default, it doesn’t do this and kubelet ends-up using first non-loopback network interface, which is usually NATed. Workaround: Modify /etc/hosts, take a look at this Vagrantfileubuntu-vagrantfile for how this can be achieved. This is currently added in the Vagrantfile. Has not been added to the scripts and could be an additional step for VirtualBox users
