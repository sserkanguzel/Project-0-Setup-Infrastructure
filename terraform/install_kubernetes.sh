#!/bin/bash
echo "Kubernetes installation started!"

# Function to log success or error
log_status() {
    if [ $? -eq 0 ]; then
        echo "$1 succeeded"
    else
        echo "$1 failed" >&2
        exit 1
    fi
}


# If kubeadm and kubelet already installed, skip install steps
if command -v kubeadm >/dev/null 2>&1 && command -v kubelet >/dev/null 2>&1; then
  echo "Kubernetes components already installed, skipping installation."
else
  echo "Installing required packages..."
  sudo apt-get install -y apt-transport-https ca-certificates curl gpg > /dev/null 2>&1
  log_status "Package installation"

  echo "Updating system..."
  sudo apt-get update > /dev/null 2>&1
  log_status "System update"

  echo "Adding Kubernetes repository..."
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null 2>&1
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null 2>&1
  log_status "Added Kubernetes repository"

  echo "Updating package list..."
  sudo apt-get update > /dev/null 2>&1
  log_status "apt-get update"

  echo "Installing Kubernetes components (kubelet, kubeadm, kubectl)..."
  sudo apt-get install -y kubelet kubeadm kubectl > /dev/null 2>&1
  log_status "Kubernetes components installation"

  echo "Holding Kubernetes components..."
  sudo apt-mark hold kubelet kubeadm kubectl > /dev/null 2>&1
  log_status "Held Kubernetes components"

  echo "Enabling and starting kubelet..."
  sudo systemctl enable --now kubelet > /dev/null 2>&1
  log_status "Start kubelet"
fi

# Run kubeadm init only on the controller node if not initialized yet
if [[ $(hostname) == "k8s-ctrlr" ]]; then
    # Check if cluster is already initialized by checking admin.conf existence
    if [ -f /etc/kubernetes/admin.conf ]; then
      echo "Cluster already initialized, skipping kubeadm init."
    else
      echo "Initializing Kubernetes cluster (controller node)..."
      sudo kubeadm init > /dev/null 2>&1
      log_status "kubeadm init"

      echo "Setting up kubeconfig..."
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
      log_status "Configured kubeconfig"

      echo "Applying Calico network plugin..."
      kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml > /dev/null 2>&1
      log_status "Installed Calico"

      echo "Waiting for controller to become ready"
      sleep 70
    fi
fi

echo "Kubernetes installation completed successfully!"
