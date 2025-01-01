variable "cluster_name" {
    description = "The short name of the Kubernetes cluster"
    type        = string
    default     = "beta"
}
variable "proxmox_host" {
    description = "The IP address of the Proxmox host"
    default = "10.0.0.100"
}
variable "proxmox_node" {
    description = "The name of the node to create the VM on"
    default = "Citadel"
}
variable "unifi_api_url" {
    description = "The URL to the Unifi controller API"
    default = "https://10.0.0.1/"
}
variable "proxmox_ssh_key" {
    description = "The path to the ssh key to use for the proxmox provider"
    default = "~/.ssh/id_rsa"
}