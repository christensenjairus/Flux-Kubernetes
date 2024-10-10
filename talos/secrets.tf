data "onepassword_item" "proxmox" {
    vault = "HomeLab K8S"
    title = "Terraform Secrets - Proxmox"
}

data "onepassword_item" "unifi" {
    vault = "HomeLab K8S"
    title = "Terraform Secrets - Unifi"
}

data "onepassword_item" "tailscale" {
    vault = "HomeLab K8S"
    title = "Terraform Secrets - TailScale"
}