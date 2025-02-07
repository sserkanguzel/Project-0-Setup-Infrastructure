#!/bin/bash
# Get updates and install containerd
sudo apt-get update -y > /dev/null 
wget https://github.com/containerd/containerd/releases/download/v2.0.2/containerd-2.0.2-linux-amd64.tar.gz > /dev/null 
sudo tar Cxzvf /usr/local containerd-2.0.2-linux-amd64.tar.gz > /dev/null 
wget https://github.com/opencontainers/runc/releases/download/v1.2.4/runc.amd64 > /dev/null 
sudo install -m 755 runc.amd64 /usr/local/sbin/runc > /dev/null 
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz > /dev/null 
sudo mkdir -p /opt/cni/bin > /dev/null 
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz > /dev/null 
sudo mkdir -p /etc/containerd > /dev/null 
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null 
# Set SystemdCgroup option enabled
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml  > /dev/null 

sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service > /dev/null 

sudo systemctl daemon-reload > /dev/null  
sudo systemctl start containerd > /dev/null 
sudo systemctl enable containerd > /dev/null 



# Enable ip forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf # Uncomment (rewrite) the option for ipforwarding
sudo sysctl -p # Apply the setting until next reboot

# Enable bridge netfilter (Enables bridging across clusters)

echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
