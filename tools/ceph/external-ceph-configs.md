https://rook.io/docs/rook/latest-release/CRDs/Cluster/external-cluster/provider-export/# Run on a proxmox host
```bash
VERSION="1.15"
RBD_DATA_POOL_NAME="vm-rbd-data"
RBD_METADATA_POOL_NAME="vm-rbd-metadata"
CEPHFS_FS_NAME="vm-cephfs"
CEPHFS_POOL_NAME="${CEPHFS_FS_NAME}-data"
CEPHFS_METADATA_POOL_NAME="${CEPHFS_POOL_NAME}-metadata"
NAMESPACE="rook-ceph-external"

rm -r ./create-external-cluster-resources.py
wget "https://github.com/rook/rook/raw/refs/heads/release-${VERSION}/deploy/examples/create-external-cluster-resources.py"
chmod +x ./create-external-cluster-resources.py

python3 create-external-cluster-resources.py \
  --rbd-data-pool-name $RBD_DATA_POOL_NAME \
  --rbd-metadata-ec-pool-name $RBD_METADATA_POOL_NAME \
  --cephfs-filesystem-name $CEPHFS_FS_NAME \
  --cephfs-data-pool-name $CEPHFS_POOL_NAME \
  --cephfs-metadata-pool-name $CEPHFS_METADATA_POOL_NAME \
  --skip-monitoring-endpoint \
  --namespace $NAMESPACE \
  --format bash
```

Copy the output. And paste in a machine where `kubectl` is pointed at your cluster. Then run.
```bash
rm -f ./import-external-cluster.sh
curl -s "https://raw.githubusercontent.com/rook/rook/release-${VERSION}/deploy/examples/import-external-cluster.sh > import-external-cluster.sh"
chmod +x ./import-external-cluster.sh

kubectl create namespace $NAMESPACE
./import-external-cluster.sh
rm -f import-external-cluster.sh
```

Install Rook as normal

```bash
export operatorNamespace="rook-ceph"
export clusterNamespace="rook-ceph-external"
curl -s "https://raw.githubusercontent.com/rook/rook/release-${VERSION}/deploy/charts/rook-ceph/values.yaml" > values.yaml
curl -s "https://raw.githubusercontent.com/rook/rook/release-${VERSION}/deploy/charts/rook-ceph-cluster/values-external.yaml" > values-external.yaml
helm install --create-namespace --namespace $operatorNamespace rook-ceph rook-release/rook-ceph -f values.yaml
helm install --create-namespace --namespace $clusterNamespace rook-ceph-cluster \
--set operatorNamespace=$operatorNamespace rook-release/rook-ceph-cluster -f values-external.yaml
rm -f values.yaml values-external.yaml
```