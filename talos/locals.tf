locals {
  all_nodes = flatten([
    for cluster_name, cluster in var.clusters : [
      for node_class, specs in cluster.node_classes : [
        for i in range(specs.count) : {
          cluster_name       = cluster.cluster_name
          node_class         = node_class
          index              = i
          vm_id              = tonumber("${cluster.cluster_id}${specs.start_ip + i}")
          cores              = specs.cores
          sockets            = specs.sockets
          memory             = specs.memory
          disks              = specs.disks
          ipv4               : {
            vm_ip            = "${cluster.networking.ipv4.subnet_prefix}.${specs.start_ip + i}"
            gateway          = "${cluster.networking.ipv4.subnet_prefix}.1"
            dns1             = cluster.networking.ipv4.dns1
            dns2             = cluster.networking.ipv4.dns2
            pod_cidr         = cluster.networking.ipv4.pod_cidr
            svc_cidr         = cluster.networking.ipv4.svc_cidr
          }
          ipv6               : {
            enabled          = cluster.networking.ipv6.enabled
            dual_stack       = cluster.networking.ipv6.enabled ? cluster.networking.ipv6.dual_stack: false
            vm_ip            = cluster.networking.ipv6.enabled ? "${cluster.networking.ipv6.subnet_prefix}::${specs.start_ip + i}" : null
            gateway          = cluster.networking.ipv6.enabled ? "${cluster.networking.ipv6.subnet_prefix}::1" : null
            dns1             = cluster.networking.ipv6.enabled ? cluster.networking.ipv6.dns1: null
            dns2             = cluster.networking.ipv6.enabled ? cluster.networking.ipv6.dns2: null
          }
        }
      ]
    ]
  ])

  cluster_config = var.clusters[terraform.workspace]

  # Now filter all_nodes to only include those from the specified cluster
  nodes = [for node in local.all_nodes : node if node.cluster_name == terraform.workspace]
}