# -*- mode: ruby -*-
# vi: set ft=ruby :
# Define Number of Nodes
NO_MASTER_NODE = 2   # Specify Number of Master Nodes
NO_WORKER_NODE = 2   # Specify Number of Worker Nodes
NO_LB_NODE = 1       # Specify Number ofLB Nodes


IP_ADDR = "192.168.30."   #IF you are changing this IP range accordingly make the changes in the script_* shell scripts 
LB_IP_START = 1
MASTER_IP_START = 4   
WORKER_IP_START = 9     



Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_check_update = false

  # Provision Master Node
  (1..NO_MASTER_NODE).each do |i|
      config.vm.define "k8s-master0#{i}" do |node|
          node.vm.provider "virtualbox" do |vb|
            vb.name = "k8s-master0#{i}"
            vb.memory = 2048
            vb.cpus = 2
          end
          node.vm.hostname = "k8s-master0#{i}"
          node.vm.network :private_network, ip: IP_ADDR + "#{MASTER_IP_START + i}"
          node.vm.provision "setup-hosts", :type => "shell", :path => "scripts/set-up.sh" do |s|
            s.args = ["eth1"]
          end
          node.vm.provision "shell", :path => "scripts/script_master0#{i}.sh"
      end
  end

  (1..NO_WORKER_NODE).each do |i|
    config.vm.define "k8s-worker0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-worker0#{i}"
        vb.memory = 2048
        vb.cpus = 1
      end
      node.vm.hostname = "k8s-worker0#{i}"
      node.vm.network :private_network, ip: IP_ADDR + "#{WORKER_IP_START + i}"
      node.vm.provision "setup-hosts", :type => "shell", :path => "scripts/set-up.sh" do |s|
        s.args = ["eth1"]
      end
      node.vm.provision "shell", :path => "scripts/script_worker0#{i}.sh" 
      end
  end

  (1..NO_LB_NODE).each do |i|
    config.vm.define "k8s-lb" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-lb"
        vb.memory = 4096
        vb.cpus = 1
      end
      node.vm.hostname = "k8s-lb"
      node.vm.network :private_network, ip: IP_ADDR + "#{LB_IP_START  + i}"
      node.vm.provision "setup-hosts", :type => "shell", :path => "scripts/set-up.sh" do |s|
        s.args = ["eth1"]
      end
      node.vm.provision "shell", :path => "scripts/script_lb.sh" 
      end
  end
end
