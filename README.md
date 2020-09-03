# Kubernetes HA Cluster using kubeadm

**VM Config :**

Using Vagrant to Automate the VM installtion for HA Cluster

* No of Master Nodes : 2 (2CPUs, 2GB RAM and running centos7)
* No of Worker Nodes : 2 (1CPUs, 2GB RAM and running centos7)
* No of LoadBalancer Node : 1 (1CPUs, 2GB and RAM running centos7)


**Vagrant Requirement :**

Download Vagrant from https://www.vagrantup.com/downloads an install 
Download this code and open the terminal from the code directory and run 

```
$ cd /c/k8s-ha-cluster
abdul@DESKTOP-SDC795Q MINGW64 /c/k8s-ha-cluster (master)
$vagrant up
```

**Installing Kubeadm -- Installation should be done on all the nodes**

**System Requirement**

* One or more machines running one of:
	* Ubuntu 16.04+
	* Debian 9+
	* CentOS 7
	* Red Hat Enterprise Linux (RHEL) 7
	* Fedora 25+
	* HypriotOS v1.0.1+
	* Container Linux (tested with 1800.6.0)
* 2 GB or more of RAM per machine (any less will leave little room for your apps)
* 2 CPUs or more
* Full network connectivity between all machines in the cluster (public or private network is fine)
  * If you have more than one network adapter, and your Kubernetes components are not reachable on the default route, we recommend you add IP route(s) so Kubernetes cluster addresses go via the appropriate adapter.


**Step 1 - Load the br_netfilter module (All Nodes).**
```
sudo modprobe br_netfilter
```
**Step 2 - Turn Off swap (All Nodes).**
```
swapoff -a
```
**Step 3 - Letting iptables see bridged traffic (All Nodes).**

```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```
**Step 4 - Installing container run-time (All Nodes).**

Install Required Packages
```
yum install -y yum-utils device-mapper-persistent-data lvm2
```
Add the docker repository
```
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
  ```
Install docker ce
```
yum update -y && yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.11 \
  docker-ce-cli-19.03.11
  ```
  Create directory for docker daemon
 ``` 
  mkdir /etc/docker
```
Setup Docker daemon
```
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
```

```
mkdir -p /etc/systemd/system/docker.service.d
```

```
systemctl daemon-reload
systemctl restart docker
sudo systemctl enable docker
```

**Step 5 - Installing kubeadm, kubelet and kubectl (All Nodes)**


Install these packages on all of your machines:
* kubeadm: the command to bootstrap the cluster.
* kubelet: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
* kubectl: the command line util to talk to your cluster.

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF


# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes


sudo systemctl enable --now kubelet
```

**Cluster Installation :**

**HA Control-Plane Installation -- Stacked ETCD**

**Step 1 - LB Configuration**

Install Nginx 

```
$sudo yum install epel-release
$sudo yum install nginx
```
Disable Selinux
```
SELINUX=disabled in the cat /etc/selinux/config and reboot the server
```
Start Nginx

```
sudo systemctl start nginx
```
Nginx configuration.

  * Create directory for loadbalancing config.

```
mkdir -p /etc/nginx/tcp.conf.d/
```
  * Add this directory path to the nginx config file  /etc/nginx/nginx.conf

```
vi /etc/nginx/nginx.conf
# including directory for tcp load balancing
include /etc/nginx/tcp.conf.d/*.conf;
```
 * create config for api-server loadbalancing

```
vi /etc/nginx/tcp.conf.d/apiserver.conf
```
```
stream {
        upstream apiserver_read {
             server 192.168.30.5:6443;                     #--> control plane node 1 ip and kube-api port
             server 192.168.30.6:6443;                     #--> control plane node 2 ip and kube-api port
        }
        server {
                listen 6443;                               # --> port on which load balancer will listen
                proxy_pass apiserver_read;
        }
}
```
  * Reload the config

```
nginx -s reload
```
  * Test the proxy 

```
yum install nc -y
```
```
nc -v LOAD_BALANCER_IP PORT
```

A connection refused error is expected because the apiserver is not yet running. A timeout, however, means the load balancer cannot communicate with the control plane node


**Step 2 -- Install kubeadm kubelet and kubectl on all the nodes please refer the kubeadm installation section.**

**Step 3 -- Initialize any one of the control plane node.**
```
sudo kubeadm init --control-plane-endpoint "LOAD_BALANCER_DNS:LOAD_BALANCER_PORT" --upload-certs
```
* You can use the --kubernetes-version flag to set the Kubernetes version to use. It is recommended that the versions of kubeadm, kubelet, kubectl and Kubernetes match.
* The --control-plane-endpoint flag should be set to the address or DNS and port of the load balancer.
* The --upload-certs flag is used to upload the certificates that should be shared across all the control-plane instances to the cluster. If instead, you prefer to copy certs across control-plane nodes manually or using automation tools, please remove this flag and refer to Manual certificate distribution section below
* Some CNI network plugins require additional configuration, for example specifying the pod IP CIDR, while others do not. See the CNI network documentation. To add a pod CIDR pass the flag --pod-network-cidr, or if you are using a kubeadm configuration file set the podSubnet field under the networking object of ClusterConfiguration.



```
sudo kubeadm init \
    --control-plane-endpoint "k8s-lb:6443" \
    --upload-certs \
    --pod-network-cidr 10.244.0.0/16 \
    --apiserver-advertise-address=192.168.30.5
```
--apiserver-advertise-address=192.168.30.5 --> address of the current master node

Output after success


```
You can now join any number of control-plane node by running the following command on each as a root:
    kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv --discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866 --control-plane --certificate-key f8902e114ef118304e561c3ecd4d0b543adc226b7a07f675f56564185ffe0c07
      
Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use kubeadm init phase upload-certs to reload certs afterward.
      
Then you can join any number of worker nodes by running the following on each as root:
    kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv --discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866


To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Step 4  - kubectl config**
```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
 

**Step 5 -- Join the other master**

Note: Run as root

```
kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv \
--discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866 \
--control-plane --certificate-key f8902e114ef118304e561c3ecd4d0b543adc226b7a07f675f56564185ffe0c07 \
--apiserver-advertise-address=192.168.56.3 
```
apiserver-advertise-address=192.168.56.3 --> address of the current master node

**Step 6 - Create a CNI for POD networking** 

Note : Run on control-plane node with non root user

``
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
``
Join the other master node using


**Step 7 -- Joint the worker nodes**

Note: Run as root

```
kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv --discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866
```

