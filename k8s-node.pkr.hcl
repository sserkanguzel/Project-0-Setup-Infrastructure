# Ubuntu Server jammy
# ---
# Packer Template to create an Ubuntu Server (jammy) on Proxmox

# Variable Definitions
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

variable "ssh_password" {
  type    = string
  default = null
}

# Resource Definiation for the VM Template
source "proxmox-iso" "fedora-kickstart" {
  disks {
    disk_size         = "32G"
    storage_pool      = "local-lvm"
    type              = "scsi"
  }
  efi_config {
    efi_storage_pool  = "local-lvm"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }
  http_directory           = "config"
  insecure_skip_tls_verify = true
  boot_iso {
    type= "scsi"
    iso_file                 = "local:iso/Fedora-Server-dvd-x86_64-29-1.2.iso"
    unmount= true
    iso_checksum= "sha512:33c08e56c83d13007e4a5511b9bf2c4926c4aa12fd5dd56d493c0653aecbab380988c5bf1671dbaea75c582827797d98c4a611f7fb2b131fbde2c677d5258ec9"

  }
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node                 = "my-proxmox"
  password             = "${var.proxmox_api_token_secret}"
  proxmox_url          = "${var.proxmox_api_url}"
  ssh_password         = "${var.ssh_password}"
  ssh_timeout          = "15m"
  ssh_username         = "root"
  template_description = "Fedora 29-1.2, generated on ${timestamp()}"
  template_name        = "fedora-29"
  username             = "${var.proxmox_api_token_id}"
}

build {
  sources = ["source.proxmox-iso.fedora-kickstart"]
}