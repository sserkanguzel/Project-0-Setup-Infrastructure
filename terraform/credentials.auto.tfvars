vms = {
  "k8s-ctrlr" = {
    name      = "k8s-ctrlr"
    vmid      = 150
    ipconfig0 = "ipaddress"
  },
  "k8s-worker-1" = {
    name      = "k8s-worker-1"
    vmid      = 151
    ipconfig0 = "ipaddress"
  },
  "k8s-worker-2" = {
    name      = "k8s-worker-2"
    vmid      = 152
    ipconfig0 = "ipaddress"
  }
}

gateway = ""
nameserver = ""
proxmox_api_url = "http:///YourIP:8006/api2/json"  # Your Proxmox IP Address
proxmox_api_token_id = "username@pam!tokenname"  # API Token ID
proxmox_api_token_secret = ""
ssh_username = ""
ssh_key = ""
cipasswd = ""

