## Should probably just do this in the UI

```bash
FS_NAME="k8s-cephfs"
POOL_NAME=$FS_NAME
APPLICATION="cephfs"
CRUSH_RULE="${POOL_NAME}-metadata"
DEVICE_CLASS="nvme"
FAILURE_DOMAIN="osd"
MIN_SIZE=2
SIZE=2

# Step 1: Create a custom CRUSH rule for NVMe OSDs (replicated, for metadata and data)
ceph osd crush rule create-replicated $CRUSH_RULE \
  default \
  $FAILURE_DOMAIN \
  $DEVICE_CLASS

# Step 2: Create the replicated pool for metadata with PG count 0 0 and autoscaler enabled
ceph osd pool create "${POOL_NAME}-metadata" 0 0 replicated $CRUSH_RULE

# Step 3: Enable autoscale for the metadata pool
ceph osd pool set "${POOL_NAME}-metadata" pg_autoscale_mode on

# Step 4: Set the pool size and min_size for metadata pool
ceph osd pool set "${POOL_NAME}-metadata" size $SIZE
ceph osd pool set "${POOL_NAME}-metadata" min_size $MIN_SIZE

# Step 5: Create the replicated pool for data with PG count 0 0 and autoscaler enabled
ceph osd pool create "${POOL_NAME}-data" 0 0 replicated $CRUSH_RULE

# Step 6: Enable autoscale for the data pool
ceph osd pool set "${POOL_NAME}-data" pg_autoscale_mode on

# Step 7: Set the pool size and min_size for data pool
ceph osd pool set "${POOL_NAME}-data" size $SIZE
ceph osd pool set "${POOL_NAME}-data" min_size $MIN_SIZE

# Step 8: Enable Bulk mode for the data pool
ceph osd pool set "${POOL_NAME}-data" bulk true

# Step 9: Set the application for both metadata and data pools
ceph osd pool application enable "${POOL_NAME}-metadata" $APPLICATION
ceph osd pool application enable "${POOL_NAME}-data" $APPLICATION

# Step 10: Create the CephFS
ceph fs new $FS_NAME "${POOL_NAME}-metadata" "${POOL_NAME}-data" --force

# Step 11: (Optional) Add the storage to Proxmox (if necessary)
# pvesm add cephfs $FS_NAME --content vztmpl,iso,backup,snippets
```

### TO DESTROY
```bash
FS_NAME="k8s-cephfs"
CRUSH_RULE="${POOL_NAME}-metadata"
umount -f /mnt/pve/$FS_NAME # on every host
pvesm remove $FS_NAME
ceph fs fail $FS_NAME
pveceph fs destroy $FS_NAME --remove-storages --remove-pools
ceph osd crush rule rm $CRUSH_RULE
rm -rf /mnt/pve/$FS_NAME # on every host
```