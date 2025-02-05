resource "proxmox_vm_qemu" "k8s-ctrlr" {
  
  # VM specifications

  name = "k8s-ctrlr"
  desc = "Kubernetes controller node"
  agent = 1
  target_node = "prox"
  vmid = "151"

  # -- Template settings

  clone = "k8s-node"
  full_clone = true

  # -- Boot Process

  onboot = true 
  automatic_reboot = true

  # -- Hardware Settings

  qemu_os = "other"
  bios = "seabios"
  cores = 2
  sockets = 1
  cpu_type = "kvm64"
  memory = 4096
  balloon = 4096

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

  ipconfig0 = "ip=192.168.1.150/24,gw=192.168.1.1"
  nameserver = "192.168.1.103"
  ciuser = var.ssh_username
  cipassword = var.cipasswd
  sshkeys = var.ssh_key
}