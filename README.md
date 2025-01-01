# Flux Kubernetes Clusters
My kubernetes cluster configurations orchestrated by Flux.

### Prerequisites
* Create the various 1Password items in a vault named `HomeLab` in the correct names and keys.
* Ensure Cilium CNI is installed in the kube-system namespace, without kube-router.


See [Cluster Creator](https://github.com/christensenjairus/ClusterCreator) to know how I set up my clusters on Proxmox.

### Install
```bash
./tools/install/install.sh
```

### List of Environments
* `development`
  * `Delta` cluster - Single-node, minimal addons, no apps. Runs `development` branch.
* `staging`
  * `Epsilon` cluster - Smaller version of a `production` cluster. Apps enabled. Runs `staging` branch. 
* `production`
  * `Zeta` and `Omega` clusters - Apps enabled. Runs `production` branch.

### Steps to add a Cluster
##### Pre-Install
* Add a `cluster-vars.yaml` file to the correct `./clusters` location
* Add an entry for your cluster in `./tools/install/subscripts/flux.sh` so the correct branch is chosen
* Add `<clusterName>-cluster` bucket to Minio for Velero backups
* Add a cluster in CloudCasa and place the cluster ID in 1Password.
* Run external ceph preparation script to set up RadosNamespace and CephFS SubVolume group

##### Post-Install
* Add the `StrictPostBuildSubstitutions` flag to the flux-system kustomization
* Correct the `radosNamespaceClusterID` and `subvolumeGroupClusterID` in your `cluster-vars.tf`

[//]: # (### List of Flux-Managed Infrastructure)
[//]: # (* Cert-Manager w/ DNS ClusterIssuer)
[//]: # (* MetalLB L2 Load Balancer)
[//]: # (* Cilium with clustermesh, externalIPs, and full eBPF)
[//]: # (* Democratic-CSI for NFS & iSCSI)
[//]: # (* Postgres Operator)
[//]: # (* Redis Operator)
[//]: # (* Splunk Operator)
[//]: # (* Goldilocks)
[//]: # (* Groundcover)
[//]: # (* Private Nginx Ingress)
[//]: # (* Public Nginx Ingress)
[//]: # (* Keda)
[//]: # (* KubeVirt)
[//]: # (* Kyverno)
[//]: # (* Victoria-Metrics)
[//]: # (* Grafana &#40;with >40 applicable dashboards&#41;)
[//]: # (* AlertManager &#40;connected to Slack&#41;)
[//]: # (* Node-Problem-Detector)
[//]: # (* NewRelic)
[//]: # (* 1Password Operator)
[//]: # (* Snapshot Controller)
[//]: # (* Metrics Server)
[//]: # (* Rook-Ceph)
[//]: # (* Velero &#40;connected to Minio&#41;)
[//]: # (* CloudCasa &#40;UI for managing velero&#41;)
[//]: # (* Vertical Pod Autoscaler)
[//]: # (* Descheduler)
[//]: # ()
[//]: # (### List of Flux-Managed Apps)
[//]: # (* GitLab)
[//]: # (  * HA Replicated Redis w/ Sentinel)
[//]: # (  * HA Postgres)
[//]: # (  * Stores gitlab & database backups in S3)
[//]: # (  * Distributed Gitaly instances)
[//]: # (  * Minio-backed object storage)
[//]: # (  * LDAP Authentication via OpenLDAP)
[//]: # (* Splunk)
[//]: # (  * 3 indexers, 3 search heads, 1 cluster manager, 1 license manager, 1 deployer)
[//]: # (  * Passwords and configs loaded from 1Password)
[//]: # (  * LDAP authentication via OpenLDAP)
[//]: # (  * `main` index backs up to S3)
[//]: # (  * Auto-installs all Splunk apps in an S3 bucket)
[//]: # (  * Managed by the splunk operator)
[//]: # (* Collectord)
[//]: # (  * Collects logs and metrics and sends to Splunk)
[//]: # (  * Tokens and configs are loaded from 1Password)
[//]: # (* Harbor Registry)
[//]: # (  * HA Replicated Redis w/ Sentinel)
[//]: # (  * HA Postgres)
[//]: # (  * Stores docker images & database backups to S3)
[//]: # (  * Kyverno policy to automatically use harbor proxy registries for all new pods.)
[//]: # (* OpenLDAP)
[//]: # (  * HA Setup &#40;3 replicas&#41;)
[//]: # (  * PHP LDAP Admin)
[//]: # (  * LDAP Self-Service Password Reset)
[//]: # (* Authelia)
[//]: # (  * HA Replicated Redis w/ Sentinel)
[//]: # (  * HA Postgres)
[//]: # (  * LDAP Authentication via OpenLDAP)
[//]: # (* Uptime-Kuma)
[//]: # (* Echo Server)
[//]: # (* Homarr)
[//]: # (* Joplin Server)
[//]: # (  * HA Postgres)
[//]: # (* Home Media Helpers)
[//]: # (  * Radarr &#40;with a 4k instance&#41;)
[//]: # (  * Sonarr &#40;with a 4k instance&#41;)
[//]: # (  * Lidarr)
[//]: # (  * Readarr)
[//]: # (  * Prowlarr)
[//]: # (  * Bazarr)
[//]: # (  * Overseerr)
[//]: # (  * Tautulli)
[//]: # (  * Deluge &#40;with built-in VPN&#41;)
[//]: # (* WordPress)
[//]: # (  * 3 instances with different URLs)
[//]: # (  * MariaDB)
[//]: # (
[//]: # &#40;  * Memcached&#41;)
[//]: # (* Vaultwarden)
[//]: # (  * HA Postgres)
[//]: # (* Portainer)
[//]: # (* Nextcloud)
[//]: # (  * HA Postgres)
[//]: # (  * HA Clustered Redis)
[//]: # (  * Helper Scripts)
[//]: # (* ClusterPlex &#40;for distributed transcoding&#41;)
[//]: # (  * 3 Transcode Workers)
[//]: # (  * Orchestrator with ServiceMonitor and Grafana Dashboard)
[//]: # (* Wazuh)
[//]: # (  * 3 indexers, 2 workers, 1 master, 1 dashboard)
[//]: # (* Kasm Workspaces)
