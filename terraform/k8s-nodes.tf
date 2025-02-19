# Define variables for your VMs
variable "vms" {
  type = map(object({
    name      = string
    vmid      = number
    ipconfig0 = string
  }))
}

# Proxmox VM configuration for Kubernetes nodes
resource "proxmox_vm_qemu" "k8s_vm" {
  for_each = var.vms

  name         = each.value.name
  desc         = "Kubernetes ${each.value.name} node"
  agent        = 1
  target_node  = "prox"
  vmid         = each.value.vmid

  clone        = "k8s-node"
  full_clone   = true
  onboot       = true
  automatic_reboot = true
  bootdisk     = "scsi0"
  qemu_os      = "other"
  bios         = "seabios"
  cores        = 2
  sockets      = 1
  cpu_type     = "kvm64"
  memory       = 4096
  balloon      = 4096
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
  scsihw = "virtio-scsi-single"
  disks {
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage   = "local-lvm"
          size      = "32G"
          iothread  = false
          replicate = false
        }
      }
    }
  }
  ipconfig0   = "ip=${each.value.ipconfig0}/24,gw=${var.gateway}"
  nameserver  = ${var.nameserver}
  ciuser      = var.ssh_username
  ssh_private_key = file("~/.ssh/id_ed25519")
}

# Install prerequisites and reboot nodes
resource "null_resource" "install_prerequisites" {
  for_each   = var.vms
  depends_on = [proxmox_vm_qemu.k8s_vm]

  provisioner "file" { # File provisioners basically copies the content from your local environment to the remote VM's
    source      = "${path.module}/install_prerequisites.sh"
    destination = "/tmp/install_prerequisites.sh"

    connection {
      type     = "ssh"
      user     = var.ssh_username
      private_key = file("~/.ssh/id_ed25519")
      host     = each.value.ipconfig0
    }
  }

  provisioner "remote-exec" { # Remote executers, runs the provisioned file inside remote VM's
    inline = [
      "chmod +x /tmp/install_prerequisites.sh",
      "sed -i 's/\r//' /tmp/install_prerequisites.sh",
      "bash /tmp/install_prerequisites.sh",
      "nohup bash -c 'sleep 5 && reboot' &"
    ]
    connection {
      type     = "ssh"
      user     = var.ssh_username
      private_key = file("~/.ssh/id_ed25519")
      host     = each.value.ipconfig0
    }
  }
}

# Install Kubernetes after reboot
resource "null_resource" "install_kubernetes" {
  for_each   = var.vms
  depends_on = [null_resource.install_prerequisites]

  provisioner "file" {
    source      = "${path.module}/install_kubernetes.sh"
    destination = "/tmp/install_kubernetes.sh"

    connection {
      type     = "ssh"
      user     = var.ssh_username
      private_key = file("~/.ssh/id_ed25519")
      host     = each.value.ipconfig0
      timeout  = "600s"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_kubernetes.sh",
      "sed -i 's/\r//' /tmp/install_kubernetes.sh",
      "bash /tmp/install_kubernetes.sh"
    ]
    connection {
      type     = "ssh"
      user     = var.ssh_username
      private_key = file("~/.ssh/id_ed25519")
      host     = each.value.ipconfig0
      timeout  = "600s"
    }
  }
}

resource "null_resource" "fetch_join_command" {
  depends_on = [null_resource.install_kubernetes]
  # Once the installation in controller node completed, this part extracts the join command from the controller node via ssh, creates a join_command.sh in your local environment, copy the content to join_command.sh file and sends it to other worker nodes.

  provisioner "local-exec" { # This part specific to my case since I am running this command to fetch data from cluster to my local win 11 pc. Syntax may change depending on the operating system in your local environment.
    command = <<-EOT
      echo '#!/bin/bash' > '${path.module}\\join_command.sh'
      echo "sudo $(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.ssh_username}@${var.vms["k8s-ctrlr"].ipconfig0} 'sudo kubeadm token create --print-join-command')" >> '${path.module}\\join_command.sh'
      EOT  
    interpreter = ["PowerShell", "-Command"]
  }
}

# Join worker nodes
resource "null_resource" "join_worker_nodes" {
  for_each   = { for key, value in var.vms : key => value if key != "k8s-ctrlr" }
  depends_on = [null_resource.fetch_join_command]

  provisioner "file" {
    source      = "${path.module}/join_command.sh"
    destination = "/tmp/join_command.sh"

    connection {
      type     = "ssh"
      user     = var.ssh_username
      private_key = file("~/.ssh/id_ed25519")
      host     = each.value.ipconfig0
      timeout  = "600s"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "iconv -f UTF-16 -t UTF-8 /tmp/join_command.sh -o /tmp/join_command_formatted.sh", # This part is specific to my case. Since my local pc saves file as UTF-16 by default. In order for an Ubuntu VM to recognize it, It is needed to convert from UTF-16 to UTF-8. This may be differ in other environments.
      "chmod +x /tmp/join_command_formatted.sh",
      "sed -i 's/[[:space:]]*$//'  /tmp/join_command_formatted.sh",
      "bash /tmp/join_command_formatted.sh"
    ]
    connection {
      type     = "ssh"
      user     = var.ssh_username
      private_key = file("~/.ssh/id_ed25519")
      host     = each.value.ipconfig0
      timeout  = "600s"
    }
  }
}
