## Should probably just do this in the Ceph Dashboard

```bash
FS_NAME="k8s-cephfs"
POOL_NAME=$FS_NAME
APPLICATION="cephfs"
ERASURE_PROFILE="${POOL_NAME}-data"
METADATA_CRUSH_RULE="${POOL_NAME}-metadata"
DEVICE_CLASS="nvme"
FAILURE_DOMAIN="osd"
MIN_SIZE=2
SIZE=2
K=2  # Number of data chunks
M=1  # Number of coding chunks

# Step 1: Create the erasure profile
ceph osd erasure-code-profile set $ERASURE_PROFILE \
  k=$K m=$M \
  crush-failure-domain=$FAILURE_DOMAIN \
  crush-device-class=$DEVICE_CLASS

# Step 2: Create a custom CRUSH rule for NVMe OSDs (replicated, for metadata only)
ceph osd crush rule create-replicated $METADATA_CRUSH_RULE \
  default \
  $FAILURE_DOMAIN \
  $DEVICE_CLASS

# Step 3: Create the erasure-coded pool for data using the erasure profile and the custom CRUSH rule
ceph osd pool create "${POOL_NAME}-data" 0 0 erasure $ERASURE_PROFILE

# Step 4: Enable autoscale for the data pool
ceph osd pool set "${POOL_NAME}-data" pg_autoscale_mode on

# Step 5: Set the pool size and min_size for the data pool
ceph osd pool set "${POOL_NAME}-data" size $SIZE
ceph osd pool set "${POOL_NAME}-data" min_size $MIN_SIZE

# Step 6: Allow EC overwrites and enable bulk mode for the data pool
ceph osd pool set "${POOL_NAME}-data" allow_ec_overwrites true
ceph osd pool set "${POOL_NAME}-data" bulk true

# Step 7: Create the metadata pool (replicated)
ceph osd pool create "${POOL_NAME}-metadata" 0 0 replicated $METADATA_CRUSH_RULE

# Step 8: Enable autoscale for the metadata pool
ceph osd pool set "${POOL_NAME}-metadata" pg_autoscale_mode on

# Step 9: Set the pool size and min_size for the metadata pool
ceph osd pool set "${POOL_NAME}-metadata" size $SIZE
ceph osd pool set "${POOL_NAME}-metadata" min_size $MIN_SIZE

# Step 10: Set the application for both metadata and data pools
ceph osd pool application enable "${POOL_NAME}-metadata" $APPLICATION
ceph osd pool application enable "${POOL_NAME}-data" $APPLICATION

# Step 11: Create the CephFS
ceph fs new $FS_NAME "${POOL_NAME}-metadata" "${POOL_NAME}-data" --force

# Step 12: (Optional) Add the storage to Proxmox
# pvesm add cephfs $FS_NAME --content vztmpl,iso,backup,snippets --pool "${POOL_NAME}-metadata" --data-pool "${POOL_NAME}-data"
```

### TO DESTROY
```bash
FS_NAME="k8s-cephfs"
ERASURE_PROFILE="${POOL_NAME}-data"
METADATA_CRUSH_RULE="${POOL_NAME}-metadata"
umount -f /mnt/pve/$FS_NAME # on every host
pvesm remove $FS_NAME
ceph fs fail $FS_NAME
pveceph fs destroy $FS_NAME --remove-storages --remove-pools
ceph osd crush rule rm $METADATA_CRUSH_RULE
ceph osd erasure-code-profile rm $ERASURE_PROFILE
rm -rf /mnt/pve/$FS_NAME # on every host
```