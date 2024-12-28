#noinspection TFIncorrectVariableType
variable "clusters" {
  description = "Configuration details for each cluster."
  type = map(object({
    cluster_name             : string                                                     # Required. Name is used in kubeconfig, cluster mesh, network name, k8s_vm_template pool. Must match the cluster name key. 14 character limit.
    cluster_id               : number                                                     # Required. Acts as the vm_id and vlan prefix. This plus the vm start ip should always be over 100 because of how proxmox likes its vmids.
    kubeconfig_file_name     : string                                                     # Required. Name of the local kubeconfig file to be created. Assumed this will be in $HOME/.kube/
    start_on_proxmox_boot    : optional(bool, true)                                       # Optional. Whether or not to start the cluster's vms on proxmox boot
    max_pods_per_node        : optional(number, 512)                                      # Optional. Max pods per node. This should be a function of the quantity of IPs in you pod_cidr and number of nodes.
    use_pve_ha               : optional(bool, false)                                      # Optional. Whether to setup PVE High Availability for the VMs.
    ssh                      : object({
      ssh_user               : string                                                     # Required. username for the remote server
      ssh_key_type           : optional(string, "ssh-ed25519")                            # Optional. Type of key to scan and trust for remote hosts. The key of this type gets added to local ~/.ssh/known_hosts.
    })
    networking               : object({
      use_pve_firewall       : optional(bool, false)                                      # Optional. Whether or not to create and enable firewall rules in proxmox to harden your cluster
      use_unifi              : optional(bool, false)                                      # Optional. Whether or not to create a vlan in Unifi.
      bridge                 : optional(string, "vmbr0")                                  # Optional. Name of the proxmox bridge to use for VM's network interface
      dns_search_domain      : optional(string, "lan")                                    # Optional. Search domain for DNS resolution
      assign_vlan            : optional(bool, false)                                      # Optional. Whether or not to assign a vlan to the network interfaces of the VMs.
      ipv4                   : object({
        subnet_prefix        : string                                                     # Required. First three octets of the host IPv4 network's subnet (assuming its a /24)
        pod_cidr             : optional(string, "10.42.0.0/16")                           # Optional. Cidr range for pod networking internal to cluster. Shouldn't overlap with ipv4 lan network. These must differ cluster to cluster if using clustermesh.
        svc_cidr             : optional(string, "10.43.0.0/16")                           # Optional. Cidr range for service networking internal to cluster. Shouldn't overlap with ipv4 lan network.
        dns1                 : optional(string, "1.1.1.1")                                # Optional. Primary dns server for vm hosts
        dns2                 : optional(string, "1.0.0.1")                                # Optional. Secondary dns server for vm hosts
        management_cidrs     : optional(string, "")                                       # Optional. Proxmox list of ipv4 IPs or cidrs that you want to be able to reach the K8s api and ssh into the hosts. Only used if use_pve_firewall is true.
        lb_cidrs             : optional(string, "")                                       # Optional. IPv4 cidrs to use for MetalLB.
      })
      ipv6                   : object({
        enabled              : optional(bool, false)                                      # Optional. Whether or not to enable IPv6 networking for the VMs and network in the cluster.
        dual_stack           : optional(bool, false)                                      # Optional. Whether or not to enable dual stack networking for the cluster. EXPECT COMPLICATIONS IF CHANGED AFTER INITIAL SETUP.
        subnet_prefix        : optional(string, "2001:db8:cafe:0000")                     # Optional. The first four hex sections of the host IPv6 network's subnet (assuming its a /64). Used for a static network configuration.
        pod_cidr             : optional(string, "2001:db8:cafe:0000:244::/80")            # Optional. Cidr range for pod networking internal to cluster. Should be a subsection of the ipv6 lan network. These must differ cluster to cluster if using clustermesh.
        svc_cidr             : optional(string, "2001:db8:cafe:0000:96::/112")            # Optional. Cidr range for service networking internal to cluster. Should be a subsection of the ipv6 lan network.
        dns1                 : optional(string, "2607:fa18::1")                           # Optional. Primary dns server for vm hosts
        dns2                 : optional(string, "2607:fa18::2")                           # Optional. Secondary dns server for vm hosts
        management_cidrs     : optional(string, "")                                       # Optional. Proxmox list of ipv6 IPs or cidrs that you want to be able to reach the K8s api and ssh into the hosts. Only used if use_pve_firewall is true.
        lb_cidrs             : optional(string, "")                                       # Optional. IPv6 cidrs to use for MetalLB.
      })
      kube_vip               : object({
        kube_vip_version     : optional(string, "0.8.4")                                  # Optional. Kube-vip version to use. Needs to be their ghcr.io docker image version
        vip_interface        : optional(string, "eth0")                                   # Optional. Interface that faces the local lan. Usually eth0 for this project.
        vip                  : string                                                     # Required. IP address of the highly available kubernetes control plane.
        vip_hostname         : string                                                     # Required. Hostname to use when querying the api server's vip load balancer (kube-vip)
        use_ipv6             : optional(bool, false)                                      # Optional. Whether or not to use an IPv6 vip. You must also set the VIP to an IPv6 address. This can be true without enabling dual_stack.
      })
    })
    node_classes             : map(object({
      count                  : number                                                     # Required. Number of VMs to create for this node class.
      pve_nodes              : optional(list(string),["Citadel","Acropolis","Parthenon"]) # Optional. Nodes that this class is allowed to run on. They will be cycled through and will repeat if count > length(pve_nodes).
      machine                : optional(string, "q35")                                    # Optional. Default to "q35". Use i400fx for partial gpu pass-through.
      cpu_type               : optional(string, "x86-64-v2-AES")                          # Optional. Default CPU type. Use 'host' for full gpu pass-through.
      cores                  : optional(number, 2)                                        # Optional. Number of cores to use.
      sockets                : optional(number, 1)                                        # Optional. Number of sockets to use or emulate.
      memory                 : optional(number, 2048)                                     # Optional. Non-ballooning memory in MB.
      disks                  : list(object({                                              # Required. First disk will be used for OS. Others can be added for longhorn, ceph, etc.
        size                 : number                                                     # Required. Size of the disk in GB.
        datastore            : string                                                     # Required. The Proxmox datastore to use for this disk.
        backup               : optional(bool, true)                                       # Optional. Backup this disk when Proxmox performs a vm backup or snapshot.
        cache_mode           : optional(string, "none")                                   # Optional. See https://pve.proxmox.com/wiki/Performance_Tweaks#Small_Overview
        aio_mode             : optional(string, "io_uring")                               # Optional. io_uring, native, or threads. Native can only be used with raw block devices. Threads is legacy.
      }))
      start_ip               : number                                                     # Required. Last octet of the ip address for the first node of the class.
      labels                 : optional(list(string), [])                                 # Optional. Kubernetes-level labels to control workload scheduling.
      taints                 : optional(list(string), [])                                 # Optional. Kubernetes-level taints to control workload scheduling.
      devices                : optional(list(object({                                     # Optional. USB or PCI(e) devices to pass-through.
        mapping              : optional(string, "")                                       # Optional. PVE datacenter-level pci or usb resource mapping name.
        type                 : optional(string, "pci")                                    # Optional. pci or usb.
        mdev                 : optional(string, "")                                       # Optional. The mediated device ID. Helpful for partial pci(e) pass-through.
        rombar               : optional(bool, true)                                       # Optional. Whether to include the rombar with the pci(e) device.
      })), [])
    }))
  }))
  default = { # create your clusters here using the above object
    "delta" = {
      cluster_name             = "delta"
      cluster_id               = 4
      kubeconfig_file_name     = "delta.yml"
      start_on_proxmox_boot    = false
      use_pve_ha               = false
      ssh = {
        ssh_user               = "line6"
      }
      networking = {
        use_pve_firewall       = true
        use_unifi              = true
        assign_vlan            = true
        ipv4 = {
          subnet_prefix        = "10.0.4"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.4.200/29,10.0.4.208/28,10.0.4.224/28,10.0.4.240/29,10.0.4.248/30,10.0.4.252/31"
        }
        ipv6 = {
          enabled              = true
          dual_stack           = true
          subnet_prefix        = "2607:fa18:47fd:400"
          pod_cidr             = "2607:fa18:47fd:400:244::/80"
          svc_cidr             = "2607:fa18:47fd:400:96::/112"
          management_cidrs     = "2607:fa18:47fd:10::7c8,2607:fa18:47fd::/48"
          lb_cidrs             = "2607:fa18:47fd:400:34::/112"
          dns1                 = "2607:fa18::1"
          dns2                 = "2607:fa18::2"
        }
        kube_vip = {
          vip                  = "10.0.4.100"
          vip_hostname         = "delta-api-server"
        }
      }
      node_classes = {
        apiserver = {
          pve_nodes  = ["Citadel"]
          count      = 1
          cores      = 12
          memory     = 24576
          disks      = [
            { datastore = "nvmes", size = 100 }
          ]
          start_ip   = 110
          labels = [
            "nodeclass=apiserver"
          ]
        }
      }
    }
    "epsilon" = {
      cluster_name             = "epsilon"
      cluster_id               = 5
      kubeconfig_file_name     = "epsilon.yml"
      start_on_proxmox_boot    = false
      use_pve_ha               = false
      ssh = {
        ssh_user               = "line6"
      }
      networking = {
        use_pve_firewall       = true
        use_unifi              = true
        assign_vlan            = true
        ipv4 = {
          subnet_prefix        = "10.0.5"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.5.200/29,10.0.5.208/28,10.0.5.224/28,10.0.5.240/29,10.0.5.248/30,10.0.5.252/31"
        }
        ipv6 = {
          enabled              = true
          dual_stack           = true
          subnet_prefix        = "2607:fa18:47fd:500"
          pod_cidr             = "2607:fa18:47fd:500:244::/80"
          svc_cidr             = "2607:fa18:47fd:500:96::/112"
          management_cidrs     = "2607:fa18:47fd:10::7c8,2607:fa18:47fd::/48"
          lb_cidrs             = "2607:fa18:47fd:500:34::/112"
          dns1                 = "2607:fa18::1"
          dns2                 = "2607:fa18::2"
        }
        kube_vip = {
          vip                  = "10.0.5.100"
          vip_hostname         = "epsilon-api-server"
        }
      }
      node_classes = {
        apiserver = {
          pve_nodes  = ["Citadel"]
          count      = 1
          cores      = 4
          memory     = 4096
          disks      = [
            { datastore = "nvmes", size = 20 }
          ]
          start_ip   = 110
          labels = [
            "nodeclass=apiserver"
          ]
        }
        general = {
          pve_nodes  = ["Citadel"]
          count      = 1
          cores      = 20
          memory     = 18432
          disks      = [
            { datastore = "nvmes", size = 20 }
          ]
          start_ip   = 130
          labels = [
            "nodeclass=general"
          ]
        }
      }
    }
    "zeta" = {
      cluster_name             = "zeta"
      cluster_id               = 6
      kubeconfig_file_name     = "zeta.yml"
      start_on_proxmox_boot    = true
      use_pve_ha               = false
      ssh = {
        ssh_user               = "line6"
      }
      networking = {
        use_pve_firewall       = true
        use_unifi              = true
        assign_vlan            = true
        ipv4 = {
          subnet_prefix        = "10.0.6"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.6.200/29,10.0.6.208/28,10.0.6.224/28,10.0.6.240/29,10.0.6.248/30,10.0.6.252/31"
          dns1                 = "10.0.6.3"
          dns2                 = "10.0.6.4"
        }
        ipv6 = {
          enabled              = true
          dual_stack           = true
          subnet_prefix        = "2607:fa18:47fd:600"
          pod_cidr             = "2607:fa18:47fd:600:244::/80"
          svc_cidr             = "2607:fa18:47fd:600:96::/112"
          management_cidrs     = "2607:fa18:47fd:10::7c8,2607:fa18:47fd::/48"
          lb_cidrs             = "2607:fa18:47fd:600:34::/112"
          dns1                 = "2607:fa18::1"
          dns2                 = "2607:fa18::2"
        }
        kube_vip = {
          vip                  = "10.0.6.100"
          vip_hostname         = "zeta-api-server"
        }
      }
      node_classes = {
        apiserver = {
          pve_nodes  = ["Citadel"]
          count     = 3
          cores     = 10
          memory    = 10240
          disks     = [
            { datastore = "nvmes", size = 20 }
          ]
          start_ip = 110
          labels   = [
            "nodeclass=apiserver"
          ]
        }
        etcd = {
          pve_nodes  = ["Citadel"]
          count     = 3
          cores     = 3
          memory    = 6144
          disks     = [
            { datastore = "nvmes", size = 100 }
          ]
          start_ip = 120
        }
        general = {
          pve_nodes  = ["Citadel"]
          count     = 3
          cores     = 24
          sockets   = 2
          memory    = 36864
          disks     = [
            { datastore = "nvmes", size = 120 }
          ]
          start_ip = 150
          labels   = [
            "nodeclass=general"
          ]
        }
      }
    }
    "omega" = {
      cluster_name             = "omega"
      cluster_id               = 7
      kubeconfig_file_name     = "omega.yml"
      start_on_proxmox_boot    = true
      use_pve_ha               = false
      ssh = {
        ssh_user               = "line6"
      }
      networking = {
        use_pve_firewall       = false
        use_unifi              = true
        assign_vlan            = true
        ipv4 = {
          subnet_prefix        = "10.0.7"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.7.200/29,10.0.7.208/28,10.0.7.224/28,10.0.7.240/29,10.0.7.248/30,10.0.7.252/31"
          dns1                 = "10.0.7.3"
          dns2                 = "10.0.7.4"
        }
        ipv6 = {
          enabled              = true
          dual_stack           = true
          subnet_prefix        = "2607:fa18:47fd:700"
          pod_cidr             = "2607:fa18:47fd:700:244::/80"
          svc_cidr             = "2607:fa18:47fd:700:96::/112"
          management_cidrs     = "2607:fa18:47fd:10::7c8,2607:fa18:47fd::/48"
          lb_cidrs             = "2607:fa18:47fd:700:34::/112"
          dns1                 = "2607:fa18::1"
          dns2                 = "2607:fa18::2"
        }
        kube_vip = {
          vip                  = "10.0.7.100"
          vip_hostname         = "zeta-api-server"
        }
      }
      node_classes = {
        apiserver = {
          pve_nodes  = ["Citadel"]
          count     = 3
          cores     = 10
          memory    = 10240
          disks     = [
            { datastore = "nvmes", size = 20 }
          ]
          start_ip = 110
          labels   = [
            "nodeclass=apiserver"
          ]
        }
        etcd = {
          pve_nodes  = ["Citadel"]
          count     = 3
          cores     = 3
          memory    = 6144
          disks     = [
            { datastore = "nvmes", size = 100 }
          ]
          start_ip = 120
        }
        general = {
          pve_nodes  = ["Citadel"]
          count     = 3
          cores     = 24
          sockets   = 2
          memory    = 36864
          disks     = [
            { datastore = "nvmes", size = 120 }
          ]
          start_ip = 150
          labels   = [
            "nodeclass=general"
          ]
        }
      }
    }
  }
}