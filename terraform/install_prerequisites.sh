#!/bin/bash
# Get updates and install containerd
if sudo apt-get update -y > /dev/null 2>&1 && \
   sudo apt-get install -y containerd > /dev/null 2>&1 && \
   sudo systemctl start containerd > /dev/null 2>&1 && \
   sudo systemctl enable containerd > /dev/null 2>&1 && \
   sudo systemctl daemon-reload > /dev/null 2>&1 && \
   sudo systemctl restart containerd > /dev/null 2>&1; then
    echo "Containerd installation and services setup completed successfully!"
else
    echo "An error occurred during the installation or configuration of containerd."
    exit 1
fi

# Create a default configuration file for containerd
if sudo mkdir -p /etc/containerd > /dev/null 2>&1 && \
   containerd config default | sudo tee /etc/containerd/config.toml > /dev/null 2>&1; then
    echo "File is copied successfully!"
else
    echo "Failed to create folder or copy the containerd config."
    exit 1
fi

# Set SystemdCgroup option enabled
sudo sed -i '/\[plugins\."io.containerd.grpc.v1.cri"\.containerd\.runtimes\.runc\.options\]/,/^$/s/^ *SystemdCgroup *= *false/            SystemdCgroup = true/' /etc/containerd/config.toml

# Enable ip forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf # Uncomment (rewrite) the option for ipforwarding
sudo sysctl -p # Apply the setting until next reboot

# Enable bridge netfilter (Enables bridging across clusters)

echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
