resource "proxmox_vm_qemu" "k8s-ctrlr" {
  
  # VM specifications
  name          = "k8s-ctrlr"
  desc          = "Kubernetes controller node"
  agent        = 1
  target_node  = "prox"
  vmid         = "150"

  # -- Template settings
  clone        = "k8s-node"
  full_clone   = true

  # -- Boot Process
  onboot       = true 
  automatic_reboot = true
  bootdisk = "scsi0"
  
  # -- Hardware Settings
  qemu_os      = "other"
  bios         = "seabios"
  cores        = 2
  sockets      = 1
  cpu_type     = "kvm64"
  memory       = 4096
  balloon      = 4096

  # -- Network Settings
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # -- Disk Settings
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
          storage = "local-lvm"
          size = "32G"
          iothread = false
          replicate = false
        }
      }
    }
  }

  # -- Cloud Init Settings
  ipconfig0   = "ip=192.168.1.150/24,gw=192.168.1.1"
  nameserver  = "192.168.1.103"
  ciuser      = var.ssh_username
  cipassword  = var.cipasswd
  sshkeys     = var.ssh_key
}

# **Provisioning Step 1: Install Prerequisites and Reboot**
resource "null_resource" "install_prerequisites" {
  depends_on = [proxmox_vm_qemu.k8s-ctrlr]

  provisioner "file" {
    source      = "${path.module}/install_prerequisites.sh"
    destination = "/tmp/install_prerequisites.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_username
      password    = var.cipasswd
      host        = "192.168.1.150"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_prerequisites.sh",
      "sed -i 's/\r//' /tmp/install_prerequisites.sh",
      "bash /tmp/install_prerequisites.sh",
      "nohup bash -c 'sleep 5 && reboot' &"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      password    = var.cipasswd
      host        = "192.168.1.150"
    }
  }
}

# **Provisioning Step 2: Install Kubernetes After Reboot**
resource "null_resource" "install_kubernetes" {
  depends_on = [null_resource.install_prerequisites]

  provisioner "file" {
    source      = "${path.module}/install_kubernetes.sh"
    destination = "/tmp/install_kubernetes.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_username
      password    = var.cipasswd
      host        = "192.168.1.150"
      timeout     = "600s"  # Allow up to 10 minutes for the reboot process
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_kubernetes.sh",
      "sed -i 's/\r//' /tmp/install_kubernetes.sh",
      "bash /tmp/install_kubernetes.sh"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      password    = var.cipasswd
      host        = "192.168.1.150"
      timeout     = "600s"  # Ensure Terraform waits for the reboot
    }
  }
}
