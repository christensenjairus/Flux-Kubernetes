# Local file resource to write the clusters config to a JSON file
resource "local_file" "cluster_config_json" {
  content  = jsonencode(local.cluster_config)
  filename = "/tmp/${local.cluster_config.cluster_name}/cluster_config.json"
}

# ----------------------------------------- Talos nocloud image download -----------------------------------------

data "talos_image_factory_extensions_versions" "main" {
  talos_version = "${local.cluster_config.talos.talos_version}"
  filters = {
    names = [
      # Official extensions you want to include in the image
      "qemu-guest-agent",
      "tailscale",
      "iscsi-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "main" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.main.extensions_info.*.name
        }
      }
    }
  )
}

# Talos nocloud image download with tailscale and qemu-guest-agent extensions
resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  content_type            = "iso"
  datastore_id            = local.cluster_config.iso_datastore
  node_name               = var.proxmox_node

  file_name               = "talos-${local.cluster_config.talos.talos_version}-nocloud-amd64.img"
  url                     = "https://factory.talos.dev/image/${talos_image_factory_schematic.main.id}/${local.cluster_config.talos.talos_version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

# ---------------- Save Kubeconfig to a file ----------------

resource "local_sensitive_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.main.kubeconfig_raw
  filename = "${pathexpand("~")}/.kube/${local.cluster_config .kubeconfig_file_name}"
}

# ---------------- Save Talosconfig to a file ----------------

resource "local_sensitive_file" "talosconfig" {
  content  = data.talos_client_configuration.main.talos_config
  filename = "${pathexpand("~")}/.talos/${local.cluster_config.talosconfig_file_name}"
}
