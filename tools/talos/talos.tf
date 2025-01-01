# Machine secrets for the Talos cluster
resource "talos_machine_secrets" "main" {}

data "talos_client_configuration" "main" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.main.client_configuration
  nodes = [for node in local.nodes : node.ipv4.vm_ip]
  endpoints = [for node in local.nodes : node.ipv4.vm_ip if node.node_class == "apiserver"]
}

data "talos_machine_configuration" "main" {
  depends_on = [ data.local_file.cilium, data.local_file.metrics_server ]

  for_each = {
    for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node
    if node.node_class != "etcd" # Handle both control plane and worker nodes, excluding etcd
  }

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${local.cluster_config.networking.vip.ip}:6443"
  machine_type     = each.value.node_class == "apiserver" ? "controlplane" : "worker"
  machine_secrets  = talos_machine_secrets.main.machine_secrets
  talos_version    = local.cluster_config.talos.talos_version
  kubernetes_version = local.cluster_config.talos.k8s_version
  docs = false
  examples = false
  config_patches = [
    templatefile("${path.module}/talos_template/talosconfig.yaml.tpl", {
      is_control_plane            = each.value.node_class == "apiserver" # Conditionally set for control plane
      hostname                    = each.key
      ipv4_local                  = each.value.ipv4.vm_ip
      ipv6_local                  = each.value.ipv6.vm_ip
      tailscale_authkey           = data.onepassword_item.tailscale.credential
      cilium_manifest_url         = data.local_file.cilium.content
      metrics_server_manifest_url = data.local_file.metrics_server.content
      cluster_config              = local.cluster_config
    })
  ]
}

resource "talos_machine_configuration_apply" "main" {
  for_each = {
    for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node
    if node.node_class != "etcd" # Apply to both control plane and worker nodes
  }

  depends_on = [ proxmox_virtual_environment_vm.node ]

  client_configuration = talos_machine_secrets.main.client_configuration
  machine_configuration_input = data.talos_machine_configuration.main[each.key].machine_configuration
  node = each.value.ipv4.vm_ip
}

resource "talos_machine_bootstrap" "main" {
  for_each = {
    for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node
    if node.node_class == "apiserver" && node.index == 0
  }
  depends_on           = [ talos_machine_configuration_apply.main ]

  client_configuration = talos_machine_secrets.main.client_configuration
  node                 = each.value.ipv4.vm_ip
}

resource "talos_cluster_kubeconfig" "main" {
  depends_on           = [ talos_machine_bootstrap.main ]

  client_configuration = talos_machine_secrets.main.client_configuration
  node                 = local.cluster_config.networking.vip.ip
}

output "talosconfig" {
  value = data.talos_client_configuration.main.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = talos_cluster_kubeconfig.main.kubeconfig_raw
  sensitive = true
}
