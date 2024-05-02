# Flux Kubernetes Clusters
My kubernetes cluster configurations orchestrated by Flux.

See [Cluster Creator](https://github.com/christensenjairus/ClusterCreator) to know how I set up my clusters on Proxmox.

### Prerequisites
* Create the various 1Password items in your vault in the correct locations. Customize to your needs.
* Ensure Cilium CNI is installed in the kube-system namespace, without kube-router. Cilium must have `l2announcements` and `externalIPs` enabled beforehand. This is required because the `infrastructure/arp` kustomization creates an L2 loadbalancer for ingress-nginx, which various helmreleases need to install correctly - including cilium, which is upgraded by flux to enable more features. Having cilium installed with l2 capabilities beforehand avoids the circular dependency between ingress-nginx and cilium.

### Install Flux
```bash
./scripts/install/onepassword-connect.sh
./scripts/install/flux.sh
```
