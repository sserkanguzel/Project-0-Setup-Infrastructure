# Project 0: Setup Kubernetes on Proxmox VM(s)

This is an infrastructure project that provides the Kubernetes environment for subsequent Data Engineering projects.

Kubernetes can be installed locally using Minikube in a single-node setup. However, for a more realistic scenario, it can also be configured as a cluster by distributing its various services across multiple nodes.

In a cluster setup, the control plane and worker nodes are deployed separately but designed to communicate with each other. The number of control plane and worker nodes can be increased based on project requirements. This ensures high availability—if a node fails for any reason, other nodes continue operating, and the control plane remains unaffected, allowing services to keep running. Additionally, new worker nodes can be added when needed to balance increased workload demands. This cluster architecture can be deployed in a cloud environment or a data center.

Based on this approach, Kubernetes will be configured with one control plane node and two worker nodes in this project. Each of these nodes will run on a separate virtual machine. For this setup, I will use my self-built home server, which is operated with Proxmox.

## System Setup

The Proxmox system has 32 GB of RAM and a 6-core processor. On top of this system, three virtual machines will be deployed, which will later host Kubernetes components. Each of these virtual machines has 4 GB of RAM and 2 CPU cores. Packer and Terraform will be used for deploying these virtual machines. Essentially, Packer will create a virtual machine template, while Terraform will generate virtual machines from this template and perform the necessary configuration tasks. The project follows the Infrastructure as Code (IaC) approach. Finally, the entire deployment process using Packer and Terraform will be executed from a local workstation (Windows 11 PC) within the same network.

## Prerequisites for Deployment

### 1. Creating an API Token for Proxmox Access
Packer and Terraform require access to the Proxmox system to create, configure virtual machines, and install the necessary components as defined in the configuration file. This is achieved through API-based communication.
- First, access the Proxmox interface.
- Navigate to the Datacenter section and go to the API Token option.
- Create a new token by specifying the user and token ID.
- Ensure that the "Privilige Separation" option is unchecked.
- Once this is completed, an API token secret will be generated. Save this secret, as it will be required later.

### 2. Installing Packer and Terraform Plugins on the Local Workstation
This project consists of two main steps: creating a virtual machine template and deploying virtual machines from the template. Packer and Terraform will be used sequentially for these tasks.
- Download the latest versions of Packer and Terraform from their official websites.

- Install Packer by extracting the downloaded zip file and adding its location to the system's PATH environment variable. Repeat the same process for Terraform.

- Verify the installation by opening Command Prompt or PowerShell and running `packer --version` and `terraform --version`.

- Once installed, use the following commands for deployment:
  - `packer init`, `packer build`
  - `terraform init`, `terraform plan`, `terraform apply`
- The `init` commands activate the relevant plugins, while the `plan` command helps detect syntax errors before deployment. Finally, the `apply` command executes the deployment process.

### 3. Downloading and Storing a Linux-Based ISO File in Proxmox Storage
Packer requires an operating system ISO file to create a virtual machine template. This ISO file provides the operating system environment on which the Kubernetes cluster will run. For this setup, **Ubuntu 22.04.5 Live Server** version is used.

## Packer

Packer connects to Proxmox via the API to perform the following tasks:
- Create a virtual machine
- Install an operating system on the virtual machine
- Install essential components such as `qemu-guest-agent` and `sudo`
- Create a user within the operating system and assign permissions

Instead of using a graphical interface, Packer enables these operations via command-line automation. Once all tasks are completed, the virtual machine is converted into a template.

The `k8s-node-template.pkr.hcl` file is the main configuration file that defines the tasks Packer will execute. It specifies:
- Connection variables
- The ISO file to be used
- Network connection type
- Hardware specifications of the virtual machine
- A boot command that bypasses the Ubuntu installation UI and triggers an automated installation (Cloud-Init)

During the Auto Install process, the local PC exposes a port, and the configurations defined in the `user-data` file are applied. The `user-data` file contains settings such as:
- System language
- Keyboard layout
- User creation (besides root)
- Installation of essential components (e.g., `sudo`, `qemu-guest-agent`)

After the main installation process, the `provisioner` block in the Packer template runs a shell script inside the VM, performing cleanup tasks and preparing the VM as a template for Cloud-Init-based deployments in Proxmox.

## Terraform

Once Packer completes its tasks, Terraform is used to:
- Deploy virtual machines from the created template
- Allocate resources based on project requirements
- Configure virtual machines to support Kubernetes cluster architecture
- Set up Kubernetes clusters

The reason for separating the process into Packer and Terraform steps is to optimize deployment. Instead of reinstalling the operating system and essential components from scratch for every virtual machine, Terraform clones the template and focuses only on Kubernetes-specific configurations. This approach significantly reduces deployment time.

The `k8s-nodes.tf` and `provider.tf` files define Terraform's tasks. While the provider file specifies the fundamental connection/access configurations, the `k8s-nodes.tf` file contains the specific configurations for the virtual machines in the cluster.

The Terraform deployment consists of four main steps:
1. **Defining Virtual Machine Hardware Specifications**
   - Specifies the CPU, RAM, storage settings and network settings for each VM.
2. **Running the `install_prerequisites.sh` Script**
   - Installs the container runtime (containerd)
   - Configures networking to allow cluster communication
   - Reboots all machines to apply changes
3. **Installing Kubernetes Components (`install_kubernetes.sh`)**
   - Up to this point, both worker and master nodes follow the same setup process.
   - In this step, the master node is initialized with `kubeadm`, and the network plugin (Calico Network Plugin) is installed.
4. **Joining Worker Nodes to the Master Node**
   - Once the master node is active, the necessary `join` command is obtained from the master node.
   - This command is sent to the worker nodes and executed, adding them to the cluster.

After Terraform completes the deployment, SSH access can be used to verify that all nodes are successfully running within the Kubernetes cluster.

