
terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source = "Terraform-for-Proxmox/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "ssh_username" {  
  type = string
  sensitive = true
}

variable "ssh_key" {  
  type = string
  sensitive = true
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = true
}