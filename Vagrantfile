# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

BEGIN {
  STATEFILE = ".vagrant-state"

  # if there's a state file, set all the envvars in the current environment
  if File.exist?(STATEFILE)
    File.read(STATEFILE).lines.map { |x| x.split("=", 2) }.each { |x,y| ENV[x] = y.strip }
  end
}

module VagrantPlugins
    module EnvState
        class Plugin < Vagrant.plugin('2')
        name 'EnvState'

        description <<-DESC
        Environment State tracker; saves the environment at `vagrant up` time and
        restores it for all other commands, and removes it at `vagrant destroy`
        time.
        DESC

        def self.up_hook(arg)
            unless File.exist?(STATEFILE) # prevent it from writing more than once.
            f = File.open(STATEFILE, "w") 
            ENV.each do |x,y|
                f.puts "%s=%s" % [x,y]
            end
            f.close
            end
        end

        def self.destroy_hook(arg)
            if File.exist?(STATEFILE) # prevent it from trying to delete more than once.
            File.unlink(STATEFILE)
            end
        end

        action_hook(:EnvState, :machine_action_up) do |hook|
            hook.prepend(method(:up_hook))
        end

        action_hook(:EnvState, :machine_action_destroy) do |hook|
            hook.prepend(method(:destroy_hook))
        end
        end
    end
end

# SET ENV
http_proxy = ENV['HTTP_PROXY'] || ENV['http_proxy'] || ''
https_proxy = ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ''
node_os = ENV['K8S_NODE_OS'] || 'ubuntu'
base_ip = ENV['K8S_IP_PREFIX'] || '193.168.5.'
num_nodes = ENV['K8S_NODES'].to_i == 0 ? 0 : ENV['K8S_NODES'].to_i

provision_every_node = <<SCRIPT
set -e
set -x
## setup the environment file. Export the env-vars passed as args to 'vagrant up'
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
sed -i '3s/^/Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"\\n/' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl restart kubelet
SCRIPT

bootstrap_master = <<SCRIPT
set -e
set -x
# Create token and export it with kube master IP
echo "Exporting Kube Master IP and Kubeadm Token..."
echo "export KUBE_MASTER_IP=$(hostname -I | cut -f2 -d' ')" >> /vagrant/config/init.sh
echo "export KUBEADM_TOKEN=$(kubeadm token generate)" >> /vagrant/config/init.sh
source /vagrant/config/init.sh
# Install Kubernetes
echo "Starting kubernetes..."
kubeadm init --kubernetes-version=v1.7.6 --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"
# Create folder to store kubernetes and network configuration
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant -R /home/vagrant/.kube
# Install Calico networking as user
sudo -u vagrant -H bash << EOF
echo "Installing Pod Network..."
kubectl apply -f /vagrant/config/calico.yaml
# Schedule Pods on master. 
kubectl taint nodes --all node-role.kubernetes.io/master-
EOF
SCRIPT

bootstrap_worker = <<SCRIPT
# Kubeadm join expects kube_master_ip and kubeadm_token
set -e
set -x
source /vagrant/config/init.sh
kubeadm join --token "${KUBEADM_TOKEN}"  "${KUBE_MASTER_IP}":6443
SCRIPT

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box_check_update = false
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end 
    if node_os == "ubuntu" then
        config.vm.box = "puppetlabs/ubuntu-16.04-64-nocm"
        config.vm.box_version = "1.0.0"
    else
        # Nothing for now, later add more OS
    end
    config.vm.provider 'virtualbox' do |v|
        v.linked_clone = true if Vagrant::VERSION >= "1.8"
    end

    node_ips = num_nodes.times.collect { |n| base_ip + "#{n+10}" }
    cluster_ip_nodes = node_ips.join(",")

    config.ssh.insert_key = false
    node_names = num_nodes.times.collect { |n| "k8s-worker#{n+1}" }
    node_peers = []
    
    # Configure Master node
    config.vm.define "k8s-master" do |k8smaster|
        k8smaster.vm.host_name = "k8s-master"
        k8smaster.vm.network :private_network, ip: base_ip + "51", virtualbox__intnet: "true"
        k8smaster.vm.provider "virtualbox" do |v|
            v.memory = 4096
            v.cpus = 2
        end
        k8smaster_ip = base_ip + "51"
        k8smaster.vm.provision :shell, inline: "sed 's/127\.0\.0\.1.*k8s.*/193\.168\.5\.51 k8s-master/' -i /etc/hosts"
        k8smaster.vm.provision "shell" do |s|
            s.inline = provision_every_node
            #s.args = [http_proxy, https_proxy]
        end
        k8smaster.vm.provision "shell" do |s|
            s.inline = bootstrap_master
        end
    end

    num_nodes.times do |n|
        node_name = node_names[n]
        node_addr = node_ips[n]

        config.vm.define node_name do |node|
            node.vm.hostname = node_name
            # Interface for K8s Cluster
            node.vm.network :private_network, ip: node_addr, virtualbox__intnet: "true"
            node.vm.provider "virtualbox" do |v|
                v.memory = 4096
                v.cpus = 2
            end
            node_ip_last = n+10
            node.vm.provision :shell, inline: "sed 's/127\.0\.0\.1.*k8s.*/193\.168\.5\.#{node_ip_last} #{node_name}/' -i /etc/hosts"
            node.vm.provision "shell" do |s|
                s.inline = provision_every_node
                #s.args = [http_proxy, https_proxy]
            end
            node.vm.provision "shell" do |s|
                s.inline = bootstrap_worker
            end
        end
    end
end
