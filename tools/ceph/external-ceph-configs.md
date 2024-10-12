https://rook.io/docs/rook/latest-release/CRDs/Cluster/external-cluster/provider-export/# Run on a proxmox host

```bash
CLUSTER_NAME=omega
NAMESPACE="rook-ceph-external"
RBD_DATA_POOL_NAME="k8s-rbd"
#RBD_DATA_POOL_NAME="k8s-rbd-data"         # not currently using erasure coding
#RBD_METADATA_POOL_NAME="k8s-rbd-metadata" # not currently using erasure coding
CEPHFS_FS_NAME="k8s-cephfs"
CEPHFS_POOL_NAME="${CEPHFS_FS_NAME}-data"
CEPHFS_METADATA_POOL_NAME="${CEPHFS_FS_NAME}-metadata"
RGW_ENDPOINT="10.0.0.100:8080"
RGW_REALM="us-west"
RGW_ZONE="us-west-1"
RGW_ZONEGROUP="us"

ceph fs subvolumegroup create $CEPHFS_FS_NAME $CLUSTER_NAME
rbd namespace create $RBD_DATA_POOL_NAME/$CLUSTER_NAME

rm -r ./create-external-cluster-resources.py ./.external-ceph-secrets.env
wget https://raw.githubusercontent.com/rook/rook/refs/heads/master/deploy/examples/create-external-cluster-resources.py
chmod +x ./create-external-cluster-resources.py

python3 create-external-cluster-resources.py \
  --namespace $NAMESPACE \
  --skip-monitoring-endpoint \
  --format bash \
  --cephfs-filesystem-name $CEPHFS_FS_NAME \
  --cephfs-data-pool-name $CEPHFS_POOL_NAME \
  --cephfs-metadata-pool-name $CEPHFS_METADATA_POOL_NAME \
  --rbd-data-pool-name $RBD_DATA_POOL_NAME \
  --rgw-endpoint $RGW_ENDPOINT \
  --rgw-skip-tls true \
  --rgw-realm-name $RGW_REALM \
  --rgw-zone-name $RGW_ZONE \
  --rgw-zonegroup-name $RGW_ZONEGROUP \
  --rgw-pool-prefix $RGW_ZONE \
  --rados-namespace $CLUSTER_NAME \
  --subvolume-group $CLUSTER_NAME \
  --output ./.external-ceph-secrets.env

#  --rbd-metadata-ec-pool-name $RBD_METADATA_POOL_NAME # not currently using erasure coding

rm ./create-external-cluster-resources.py
```

Input your secrets into the appropriate 'Ceph' secrets in 1Password.

## Install Rook operator as normal

```bash
helm upgrade --install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph
```

Apply the `external-ceph` infrastructure configuration afterward

## RadosNamespace and CephFS Subvolumes
https://rook.io/docs/rook/latest/CRDs/Block-Storage/ceph-block-pool-rados-namespace-crd/#spec

Once the radosnamespace is 'Ready', take the clusterID and place it in the `storageClass` and `volumeSnapshotClass` under .parameters.clusterID

```bash
echo "RBD ClusterID: $(kubectl -n $NAMESPACE get cephblockpoolradosnamespace/$CLUSTER_NAME -o jsonpath='{.status.info.clusterID}')"
echo "CephFS ClusterID: $(kubectl -n $NAMESPACE get cephfilesystemsubvolumegroups/$CLUSTER_NAME -o jsonpath='{.status.info.clusterID}')"
```
