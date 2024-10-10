resource "proxmox_virtual_environment_pool" "operations_pool" {
  depends_on = [unifi_network.vlan]
  # had to add the Pool.Audit permission to the Terraform role in Proxmox for this to work
  for_each = {
    for key, value in var.clusters : key => value
    if key == terraform.workspace
  }
  comment = "Managed by Terraform"
  pool_id = upper(each.key) # pool id is the cluster name in all caps
}

# Dynamic creation of control plane (cp) nodes based on the selected cluster configuration
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "node" {
  depends_on = [proxmox_virtual_environment_pool.operations_pool]
  for_each = { for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node }

  description  = "Managed by Terraform"
  vm_id = each.value.vm_id
  name = "${each.value.cluster_name}-${each.value.node_class}-${each.value.index}"
  tags = [
    "k8s",
    each.value.cluster_name,
    each.value.node_class,
  ]
  node_name = var.proxmox_node
  operating_system {
    type = "l26"
  }
  cpu {
    cores    = each.value.cores
    sockets  = each.value.sockets
    hotplugged = each.value.cores * each.value.sockets
    numa = true
    type = "x86-64-v2-AES"
    flags = []
  }
  memory {
    dedicated = each.value.memory
  }
  dynamic "disk" {
    for_each = each.value.disks
    content {
      file_id       = disk.value.index == 0 ? proxmox_virtual_environment_download_file.talos_nocloud_image.id : null # Set file_id only if it's the first disk
      interface     = "virtio${disk.value.index}"
      size          = disk.value.size
      datastore_id  = disk.value.datastore
      file_format   = "raw"
      backup        = disk.value.backup # backup the disks during vm backup
      # https://pve.proxmox.com/wiki/Performance_Tweaks
      iothread      = true
      cache         = "writeback" # none is proxmox default. Writeback provides a little extra speed with more risk during power failure.
      aio           = "native"    # io_uring is proxmox default. Native can only be used with raw block devices.
      discard       = "ignore"    # proxmox default
      ssd           = false       # not possible with virtio
    }
  }
  agent {
    enabled = true
    timeout = "15m"
    trim = true
    type = "virtio"
  }
  vga {
    memory = 16
    type = "virtio"
  }
  initialization {
    interface = "ide2"
    datastore_id = each.value.disks[0].datastore
    dynamic "ip_config" {
      for_each = [1]  # This ensures the block is always created
      content {
        dynamic "ipv4" {
          for_each = [1]  # This ensures the block is always created
          content {
            address = "${each.value.ipv4.vm_ip}/24"
            gateway = each.value.ipv4.gateway
          }
        }

        dynamic "ipv6" {
          for_each = each.value.ipv6.enabled ? [1] : []
          content {
            address = "${each.value.ipv6.vm_ip}/64"
            gateway = each.value.ipv6.gateway
          }
        }
      }
    }
    dns {
      domain = local.cluster_config.networking.dns_search_domain
      servers = concat(
        [each.value.ipv4.dns1, each.value.ipv4.dns2, each.value.ipv4.gateway],
          each.value.ipv6.enabled ? [each.value.ipv6.dns1, each.value.ipv6.dns2] : []
      )
    }
  }
  network_device {
    vlan_id = local.cluster_config.networking.assign_vlan ? local.cluster_config.networking.vlan_id: null
    bridge  = local.cluster_config.networking.bridge
  }
  reboot = false
  migrate = true
  on_boot = local.cluster_config.start_on_proxmox_boot
  started = true
  pool_id = upper(each.value.cluster_name)
  lifecycle {
    ignore_changes = [
      tags,
      description,
      clone,
      disk, # don't remake disks, could cause data loss! Can comment this out if no production data is present
    ]
  }
}
