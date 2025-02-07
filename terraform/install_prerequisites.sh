#!/bin/bash

# Function to log success or error
log_status() {
    if [ $? -eq 0 ]; then
        echo "$1 succeeded"
    else
        echo "$1 failed" >&2
        exit 1
    fi
}

# Stage 1: Update system and install containerd
echo "Stage 1: Updating system and installing containerd..."
sudo apt-get update -y > /dev/null 2>&1
log_status "System update"

wget https://github.com/containerd/containerd/releases/download/v2.0.2/containerd-2.0.2-linux-amd64.tar.gz > /dev/null 2>&1
log_status "Downloaded containerd tarball"

sudo tar Cxzvf /usr/local containerd-2.0.2-linux-amd64.tar.gz > /dev/null 2>&1
log_status "Extracted containerd"

# Stage 2: Install runc
echo "Stage 2: Installing runc..."
wget https://github.com/opencontainers/runc/releases/download/v1.2.4/runc.amd64 > /dev/null 2>&1
log_status "Downloaded runc"

sudo install -m 755 runc.amd64 /usr/local/sbin/runc > /dev/null 2>&1
log_status "Installed runc"

# Stage 3: Install CNI plugins
echo "Stage 3: Installing CNI plugins..."
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz > /dev/null 2>&1
log_status "Downloaded CNI plugins"

sudo mkdir -p /opt/cni/bin > /dev/null 2>&1
log_status "Created CNI directory"

sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz > /dev/null 2>&1
log_status "Extracted CNI plugins"

# Stage 4: Configure containerd
echo "Stage 4: Configuring containerd..."
sudo mkdir -p /etc/containerd > /dev/null 2>&1
log_status "Created containerd config directory"

containerd config default | sudo tee /etc/containerd/config.toml > /dev/null 2>&1
log_status "Generated default containerd config"

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml > /dev/null 2>&1
log_status "Enabled SystemdCgroup"

# Stage 5: Install containerd service
echo "Stage 5: Installing containerd service..."
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service > /dev/null 2>&1
log_status "Downloaded containerd service file"

sudo systemctl daemon-reload > /dev/null 2>&1
log_status "Reloaded systemd daemon"

sudo systemctl start containerd > /dev/null 2>&1
log_status "Started containerd"

sudo systemctl enable containerd > /dev/null 2>&1
log_status "Enabled containerd on boot"

# Stage 6: Enable IP forwarding
echo "Stage 6: Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
log_status "Enabled IP forwarding"

sudo sysctl -p > /dev/null 2>&1
log_status "Applied IP forwarding setting"

# Stage 7: Enable bridge netfilter
echo "Stage 7: Enabling bridge netfilter..."
echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf > /dev/null 2>&1
log_status "Enabled bridge netfilter"

echo "Setup completed successfully!"
