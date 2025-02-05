resource "proxmox_vm_qemu" "k8s-ctrlr" {
  
  # VM specifications

  name = "k8s-ctrlr"
  desc = "Kubernetes controller node"
  agent = 1
  target_node = "prox"
  vmid = "151"

  # -- Template settings

  clone = "k8s-node"
  full_clone = false

  # -- Boot Process

  onboot = true 
  automatic_reboot = true

  # -- Hardware Settings

  qemu_os = "other"
  bios = "seabios"
  cores = 1
  sockets = 1
  cpu_type = "kvm64"
  memory = 2048
  balloon = 2048

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
  ciuser = "SSG"
  cipassword = "passwordd"
  sshkeys = var.ssh_key
}