# Project 0: Setup Kubernetes on Proxmox VM(s)

This is an infrastructure project that provides the Kubernetes environment for subsequent Data Engineering projects.

Kubernetes can be installed locally using Minikube in a single-node setup. However, for a more realistic scenario, it can also be configured as a cluster by distributing its various services across multiple nodes.

In a cluster setup, the control plane and worker nodes are deployed separately but designed to communicate with each other. The number of control plane and worker nodes can be increased based on project requirements. This ensures high availability—if a node fails for any reason, other nodes continues operating, and the control plane remains unaffected, allowing services to keep running. Additionally, new worker nodes can be added when needed to balance increased workload demands. This cluster architecture can be deployed in a cloud environment or a data center.

Based on this approach, Kubernetes will be configured with one control plane node and two worker nodes in this project. Each of these nodes will run on a separate virtual machine. For this setup, I will use my self-built home server, which is operated with Proxmox.