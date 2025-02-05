# Packer Template to create an Ubuntu Server on Proxmox

# Variables and Resources Definitions

variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

variable "ssh_username" {
  type    = string
  default = null
}

source "proxmox-iso" "k8s-nodebuild" {

  disks { 
    disk_size         = "32G"
    storage_pool      = "local-lvm"
    type              = "scsi"
  }

  insecure_skip_tls_verify = true
  

  boot_iso {
    type= "scsi"
    iso_file = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
    unmount= true
    iso_checksum= "none"
    iso_storage_pool = "local"
  }


  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
    firewall = "false"
  }


  node= "prox"
  vm_id = "900"
  vm_name = "k8s-node-template"
  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"
  cores = "2"
  memory = "4096"
  
  cloud_init = true
  cloud_init_storage_pool = "local-lvm"
  
  token                = "${var.proxmox_api_token_secret}"
  proxmox_url          = "${var.proxmox_api_url}"
  ssh_private_key_file = "C:/Users/SSG/.ssh/id_ed25519"
  ssh_username         = "${var.ssh_username}"
  ssh_timeout          = "15m"


  template_description = "Kubernetes node template, generated on ${timestamp()}"
  template_name        = "k8s-node"
  username             = "${var.proxmox_api_token_id}"
  
  http_directory = "http" ## For autoinstall configurations, Packer opens up a port on your workstation and provides the configurations under http folder through that port. 

  
  # PACKER Boot Commands

  boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>", # Auto install command is initiated in boot process and via this command. Your local workstations ip and port is given via packer during the deployment process. 
        "<f10><wait>"
    ]
  boot = "c"
  boot_wait = "5s"

}

build {
  sources = ["source.proxmox-iso.k8s-nodebuild"]
  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
        "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
        "sudo rm /etc/ssh/ssh_host_*",
        "sudo truncate -s 0 /etc/machine-id",
        "sudo apt -y autoremove --purge",
        "sudo apt -y clean",
        "sudo apt -y autoclean",
        "sudo cloud-init clean",
        "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
        "sudo rm -f /etc/netplan/00-installer-config.yaml",
        "sudo sync"
    ]
  }

 # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
 provisioner "file" {
    source = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
 }

# Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
 provisioner "shell" {
    inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
 }
}
