# Flux Kubernetes Clusters
My kubernetes cluster configurations orchestrated by Flux.

### Prerequisites
* Create the various 1Password items in your vault in the correct locations. Customize to your needs.
* Ensure Cilium CNI is installed in the kube-system namespace, without kube-router. Cilium must have `l2announcements` and `externalIPs` enabled beforehand. This is required because the `infrastructure/arp` kustomization creates an L2 loadbalancer for ingress-nginx, which various helmreleases need to install correctly - including cilium, which is upgraded by flux to enable more features. Having cilium installed with l2 capabilities beforehand avoids the circular dependency between ingress-nginx and cilium.

### Install Flux
```bash
./scripts/install/onepassword-connect.sh
./scripts/install/flux.sh
```

### List of Clusters
* Delta - single-node cluster, used for testing. No ceph storage and minimal addons and no apps.
* Epsilon - simple multi-node cluster, used for testing. Has ceph, but no production apps.
* Zeta - complex production cluster. All features enabled.

See [Cluster Creator](https://github.com/christensenjairus/ClusterCreator) to know how I set up my clusters on Proxmox.

### List of Flux-Managed Apps
* Cert-Manager w/ DNS ClusterIssuer
* Cilium with clustermesh, l2announcements, externalIPs, and full eBPF
* Democratic-CSI for NFS & iSCSI
* Postgres Operator
* Redis Operator
* Goldilocks
* Groundcover
* Harbor Registry
  * HA Redis
  * HA Postgres
  * Stores docker images & database backups in Minio
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
* Rook-Ceph
* Velero (connected to Minio)
* Vertical Pod Autoscaler