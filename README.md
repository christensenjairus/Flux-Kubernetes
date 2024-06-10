# Flux Kubernetes Clusters
My kubernetes cluster configurations orchestrated by Flux.

### Prerequisites
* Create the various 1Password items in your vault in the correct locations. Customize to your needs.
* Ensure Cilium CNI is installed in the kube-system namespace, without kube-router. Cilium must have `l2announcements` and `externalIPs` enabled beforehand. This is required because the `infrastructure/arp` kustomization creates an L2 loadbalancer for ingress-nginx, which various helmreleases need to install correctly - including cilium, which is upgraded by flux to enable more features. Having cilium installed with l2 capabilities beforehand avoids the circular dependency between ingress-nginx and cilium.

### Install Flux
```bash
./tools/install/onepassword-connect.sh
./tools/install/flux.sh
```

### List of Clusters
* Delta - single-node cluster, used for testing. No ceph storage and minimal addons and no apps.
* Epsilon - simple multi-node cluster, used for testing. Has ceph, but no production apps.
* Zeta - complex production cluster. All features enabled.

See [Cluster Creator](https://github.com/christensenjairus/ClusterCreator) to know how I set up my clusters on Proxmox.

### List of Flux-Managed Infrastructure
* Cert-Manager w/ DNS ClusterIssuer
* MetalLB L2 Load Balancer
* Cilium with clustermesh, externalIPs, and full eBPF
* Democratic-CSI for NFS & iSCSI
* Postgres Operator
* Redis Operator
* Splunk Operator
* Goldilocks
* Groundcover
* Private Nginx Ingress
* Public Nginx Ingress
* Keda
* KubeVirt
* Kyverno
* Victoria-Metrics
* Grafana (with >40 applicable dashboards)
* AlertManager (connected to Slack)
* Node-Problem-Detector
* NewRelic
* 1Password Operator
* Snapshot Controller
* Metrics Server
* Rook-Ceph
* Velero (connected to Minio)
* CloudCasa (UI for managing velero)
* Vertical Pod Autoscaler
* Descheduler

### List of Flux-Managed Apps
* GitLab
  * HA Replicated Redis w/ Sentinel
  * HA Postgres
  * Stores gitlab & database backups in S3
  * Distributed Gitaly instances
  * Minio-backed object storage
  * LDAP Authentication via OpenLDAP
* Splunk
  * 3 indexers, 3 search heads, 1 cluster manager, 1 license manager, 1 deployer
  * Passwords and configs loaded from 1Password
  * LDAP authentication via OpenLDAP
  * `main` index backs up to S3
  * Auto-installs all Splunk apps in an S3 bucket
  * Managed by the splunk operator
* Collectord
  * Collects logs and metrics and sends to Splunk
  * Tokens and configs are loaded from 1Password
* Harbor Registry
  * HA Replicated Redis w/ Sentinel
  * HA Postgres
  * Stores docker images & database backups to S3
* OpenLDAP
  * HA Setup (3 replicas)
  * PHP LDAP Admin
  * LDAP Self-Service Password Reset
* Authelia
  * HA Replicated Redis w/ Sentinel
  * HA Postgres
  * LDAP Authentication via OpenLDAP
* Uptime-Kuma
* Echo Server
* Homarr
* Joplin Server
  * HA Postgres
* Home Media Helpers
  * Radarr (with a 4k instance)
  * Sonarr (with a 4k instance)
  * Lidarr
  * Readarr
  * Prowlarr
  * Bazarr
  * Overseerr
  * Tautulli
  * Deluge (with built-in VPN)
* WordPress
  * 3 instances with different URLs
  * MariaDB
[//]: # (  * Memcached)
* Vaultwarden
  * HA Postgres
* Portainer
* Nextcloud
  * HA Postgres
  * HA Clustered Redis
  * Helper Scripts
