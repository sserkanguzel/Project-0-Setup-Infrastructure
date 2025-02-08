variable "vms" {
  type = map(object({
    name      = string
    vmid      = number
    ipconfig0 = string
  }))

  default = {
    "k8s-ctrlr" = {
      name      = "k8s-ctrlr"
      vmid      = 150
      ipconfig0 = "192.168.1.150"
    },
    "k8s-worker-1" = {
      name      = "k8s-worker-1"
      vmid      = 151
      ipconfig0 = "192.168.1.151"
    },
    "k8s-worker-2" = {
      name      = "k8s-worker-2"
      vmid      = 152
      ipconfig0 = "192.168.1.152"
    }
  }
}

resource "proxmox_vm_qemu" "k8s_vm" {
  for_each = var.vms

  name         = each.value.name
  desc         = "Kubernetes ${each.value.name} node"
  agent        = 1
  target_node  = "prox"
  vmid         = each.value.vmid

  # -- Template settings
  clone        = "k8s-node"
  full_clone   = true

  # -- Boot Process
  onboot       = true
  automatic_reboot = true
  bootdisk     = "scsi0"

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
          storage   = "local-lvm"
          size      = "32G"
          iothread  = false
          replicate = false
        }
      }
    }
  }

  # -- Cloud Init Settings
  ipconfig0   = "ip=${each.value.ipconfig0}/24,gw=192.168.1.1"
  nameserver  = "192.168.1.103"
  ciuser      = var.ssh_username
  cipassword  = var.cipasswd
  sshkeys     = var.ssh_key
}

# **Provisioning Step 1: Install Prerequisites and Reboot**
resource "null_resource" "install_prerequisites" {
  for_each   = var.vms
  depends_on = [proxmox_vm_qemu.k8s_vm]

  provisioner "file" {
    source      = "${path.module}/install_prerequisites.sh"
    destination = "/tmp/install_prerequisites.sh"

    connection {
      type     = "ssh"
      user     = var.ssh_username
      password = var.cipasswd
      host     = each.value.ipconfig0
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
      type     = "ssh"
      user     = var.ssh_username
      password = var.cipasswd
      host     = each.value.ipconfig0
    }
  }
}

# **Provisioning Step 2: Install Kubernetes After Reboot**
resource "null_resource" "install_kubernetes" {
  for_each   = var.vms
  depends_on = [null_resource.install_prerequisites]

  provisioner "file" {
    source      = "${path.module}/install_kubernetes.sh"
    destination = "/tmp/install_kubernetes.sh"

    connection {
      type     = "ssh"
      user     = var.ssh_username
      password = var.cipasswd
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
      password = var.cipasswd
      host     = each.value.ipconfig0
      timeout  = "600s"
    }
  }
}
