terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.69.0"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = ">= 0.64.0"
    }
    unifi = {
      source = "paultyng/unifi"
      version = ">= 0.41.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = ">= 0.6.0"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = ">= 2.1.2"
    }
  }

  backend "s3" {
    bucket = "terraform-state"
    key    = "flux_kubernetes.tfstate"
    region = "default"

    endpoints = {
      s3 = "https://s3.christensencloud.us"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "aws" {
  region = "default"

  endpoints {
    s3 = "https://s3.christensencloud.us"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
}

provider "unifi" {
  username = data.onepassword_item.unifi.username
  password = data.onepassword_item.unifi.credential
  api_url  = var.unifi_api_url
  allow_insecure = true
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/api2/json"
  api_token = data.onepassword_item.proxmox.credential
  ssh {
    agent = true
    username = data.onepassword_item.proxmox.username
    private_key = file(var.proxmox_ssh_key)
  }
  insecure = true
}
