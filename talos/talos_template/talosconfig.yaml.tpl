machine:
  nodeLabels:
    node.cloudprovider.kubernetes.io/platform: proxmox
    topology.kubernetes.io/region: ${cluster_config.region}
    topology.kubernetes.io/zone: ${cluster_config.zone}

  # Control Plane: Include certSANs for control plane nodes
  %{ if is_control_plane == true }
  certSANs:
    - ${cluster_config.networking.vip.ip}
    - ${cluster_config.networking.vip.vip_hostname}
    - ${ipv4_local}
    - ${hostname}.${cluster_config.networking.tailscale_domain}
    %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
    - ${ipv6_local}
    %{ endif }
  %{ endif }

  kubelet:
    defaultRuntimeSeccompProfileEnabled: true
    #disableManifestsDirectory: true
    extraArgs:
      # rotate-server-certificates: true # should be enabled for production, but not necessary for a homelab
      %{ if is_control_plane == true }
      node-labels: "project.io/node-pool=control-plane"
      %{ else }
      node-labels: "project.io/node-pool=worker"
      %{ endif }
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",", cluster_config.networking.ipv4.svc_cidr)[0], 10)}
      %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
      - ${cidrhost(split(",", cluster_config.networking.ipv6.svc_cidr)[0], 10)}
      %{ endif }
    nodeIP:
      validSubnets:
        - ${cluster_config.networking.ipv4.subnet_prefix}.0/24
        %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
        - ${cluster_config.networking.ipv6.subnet_prefix}::/64
        %{ endif }

  network:
    hostname: "${hostname}"
    interfaces:
      - interface: eth0
        addresses:
          - "${ipv4_local}/24"
          %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
          - "${ipv6_local}/64"
          %{ endif }
        %{ if is_control_plane == true }
        vip:
          ip: ${cluster_config.networking.vip.ip}
        %{ endif }
      - interface: dummy0
        addresses:
          - 169.254.2.53/32

    extraHostEntries:
      %{ if is_control_plane == true }
      - ip: 127.0.0.1
      %{ else }
      - ip: ${cluster_config.networking.vip.ip}
      %{ endif }
        aliases:
          - "${cluster_config.networking.vip.vip_hostname}"

    nameservers:
      - 1.1.1.1
      - 8.8.8.8
    kubespan:
      enabled: false

  install:
    disk: /dev/vda
    image: ghcr.io/siderolabs/installer:${cluster_config.talos.talos_version}
    bootloader: true
    wipe: false

  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096

  systemDiskEncryption:
    state:
      provider: luks2
      options:
        - no_read_workqueue
        - no_write_workqueue
      keys:
        - nodeID: {}
          slot: 0
    ephemeral:
      provider: luks2
      options:
        - no_read_workqueue
        - no_write_workqueue
      keys:
        - nodeID: {}
          slot: 0

  time:
    servers:
      - time.cloudflare.com

  features:
    rbac: true
    stableHostname: true
    hostDNS:
      enabled: true
      resolveMemberNames: true
    %{ if is_control_plane == true }
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
      allowedKubernetesNamespaces:
        - kube-system
    %{ endif }

  kernel:
    modules:
      - name: br_netfilter
        parameters:
          - nf_conntrack_max=131072
      - name: overlay
      - name: rbd
      - name: ceph

cluster:
  controlPlane:
    endpoint: https://${cluster_config.networking.vip.vip_hostname}:6443
  network:
    dnsDomain: "cluster.local"
    podSubnets:
      - ${cluster_config.networking.ipv4.pod_cidr}
      %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
      - ${cluster_config.networking.ipv6.pod_cidr}
      %{ endif }
    serviceSubnets:
      - ${cluster_config.networking.ipv4.svc_cidr}
      %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
      - ${cluster_config.networking.ipv6.svc_cidr}
      %{ endif }
    cni:
      name: none
  proxy:
    disabled: true

%{ if is_control_plane == true }
  adminKubeconfig:
    certLifetime: 48h0m0s
  apiServer:
    resources:
      requests:
        cpu: 500m   # 2x the default
        memory: 1Gi # 2x the default
  etcd:
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
      quota-backend-bytes: 8589934592 # 8Gi, the maximum that is recommended
    advertisedSubnets:
      - "${cluster_config.networking.ipv4.subnet_prefix}.0/24"
      %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
      - "${cluster_config.networking.ipv6.subnet_prefix}::/64"
      %{ endif }
    listenSubnets:
      - "${cluster_config.networking.ipv4.subnet_prefix}.0/24"
      %{ if cluster_config.networking.ipv6.enabled && cluster_config.networking.ipv6.dual_stack }
      - "${cluster_config.networking.ipv6.subnet_prefix}::/64"
      %{ endif }
  extraManifests:
    - ${ cilium_manifest_url } # Cilium
    - ${ metrics_server_manifest_url } # HA metrics-server
    - https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml # kubelet-serving-cert-approver
%{ else }
  discovery:
    enabled: false
%{ endif }
---
apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: tailscale
environment:
  - TS_AUTHKEY=${tailscale_authkey}
