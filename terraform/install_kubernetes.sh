#!/bin/bash
echo "Post reboot phase started!"

# Function to log success or error
log_status() {
    if [ $? -eq 0 ]; then
        echo "$1 succeeded"
    else
        echo "$1 failed" >&2
        exit 1
    fi
}

echo "Updating system"
sudo apt-get update > /dev/null 2>&1
log_status "System update"

echo "Installing additional packages and adding kubernetes gpg key.."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg > /dev/null 2>&1
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null 2>&1
log_status "Packages are installed"

echo "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null 2>&1
log_status "Adding Kubernetes repository"

echo "Updating package list after adding Kubernetes repo..."
sudo apt-get update > /dev/null 2>&1
log_status "apt-get update after adding repo"

echo "Installing Kubernetes components (kubelet, kubeadm, kubectl)..."
sudo apt-get install -y kubelet kubeadm kubectl > /dev/null 2>&1
log_status "apt-get install Kubernetes components"

echo "Put kubernetes components on hold"
sudo apt-mark hold kubelet kubeadm kubectl > /dev/null 2>&1
log_status "Kubernetes components are on hold"

echo "Enabling and starting kubelet..."
sudo systemctl enable --now kubelet > /dev/null 2>&1
log_status "systemctl enable kubelet"

echo "Initializing Kubernetes cluster..."
sudo kubeadm init > /dev/null 2>&1
log_status "kubeadm init"

echo "Setting up kubeconfig for the user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
log_status "User setup"

echo "Applying Calico network plugin..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml > /dev/null 2>&1
log_status "Calico network plugin"

echo "Restarting kubelet..."
sudo systemctl restart kubelet > /dev/null 2>&1
log_status "Kubelet restart"

echo "Kubernetes installed succesfully!"

