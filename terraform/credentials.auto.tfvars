proxmox_api_url = "http://192.168.1.79:8006/api2/json"  # Your Proxmox IP Address
proxmox_api_token_id = "root@pam!terraform"  # API Token ID
proxmox_api_token_secret = "b0fb2538-5a08-4f0c-9e85-4895f4b808d4"
ssh_username = "SSG"
ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpRB3zL3/QVlTBxHRtITz2vavDcv+FEaC2/1U8IFOUs ssg@DESKTOP-1SK04NB"
cipasswd = "passwordd"

vms = {
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