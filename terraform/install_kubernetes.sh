#!/bin/bash

echo "Post reboot phase started!"

# Function to check if a command succeeds and print an appropriate message
check_status() {
    if [ $? -eq 0 ]; then
        echo "$1: Success"
    else
        echo "$1: Failed"
        exit 1
    fi
}

# Update package lists
echo "Updating package list..."
sudo apt-get update > /dev/null 2>&1
check_status "apt-get update"

# Install required packages
echo "Installing necessary packages (apt-transport-https, ca-certificates, curl, gpg)..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg > /dev/null 2>&1
check_status "apt-get install"

# Add Kubernetes GPG key
echo "Adding Kubernetes GPG key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null 2>&1
check_status "curl and gpg key add"

# Add Kubernetes repository
echo "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null 2>&1
check_status "Adding Kubernetes repository"

# Update package lists again to include the Kubernetes repository
echo "Updating package list after adding Kubernetes repo..."
sudo apt-get update > /dev/null 2>&1
check_status "apt-get update after adding repo"

# Install Kubernetes components (kubelet, kubeadm, kubectl)
echo "Installing Kubernetes components (kubelet, kubeadm, kubectl)..."
sudo apt-get install -y kubelet kubeadm kubectl > /dev/null 2>&1
check_status "apt-get install Kubernetes components"

# Mark Kubernetes components to prevent them from being upgraded
echo "Marking kubelet, kubeadm, kubectl to be held..."
sudo apt-mark hold kubelet kubeadm kubectl > /dev/null 2>&1
check_status "apt-mark hold Kubernetes components"

# Enable and start kubelet
echo "Enabling and starting kubelet..."
sudo systemctl enable --now kubelet > /dev/null 2>&1
check_status "systemctl enable kubelet"

# Initialize Kubernetes master node using kubeadm
echo "Initializing Kubernetes cluster..."
sudo kubeadm init > /dev/null 2>&1
check_status "kubeadm init"

# Set up kubeconfig for the user
echo "Setting up kubeconfig for the user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
check_status "Setting up kubeconfig"

# Apply Calico networking manifest
echo "Applying Calico network plugin..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml > /dev/null 2>&1
check_status "Calico network plugin"

# Restart kubelet
echo "Restarting kubelet..."
sudo systemctl restart kubelet > /dev/null 2>&1
check_status "systemctl restart kubelet"

echo "Setup completed successfully!"
