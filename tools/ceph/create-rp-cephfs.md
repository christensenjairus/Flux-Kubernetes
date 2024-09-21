## Should probably just do this in the UI

```bash
# Variables
FS_NAME="k8s-cephfs"
POOL_NAME=$FS_NAME
APPLICATION="cephfs"
CRUSH_RULE="${POOL_NAME}-metadata"
DEVICE_CLASS="nvme"
FAILURE_DOMAIN="osd"
MIN_SIZE=2
SIZE=2
PG_NUM=128

# Step 1: Create a custom CRUSH rule for NVMe OSDs (replicated, for metadata and data)
ceph osd crush rule create-replicated $CRUSH_RULE \
  default \
  $FAILURE_DOMAIN \
  $DEVICE_CLASS

# Step 2: Create the replicated pool for metadata
pveceph pool create "${POOL_NAME}-metadata" \
  --crush_rule=$CRUSH_RULE \
  --application=$APPLICATION \
  --min_size=$MIN_SIZE \
  --size=$SIZE \
  --pg_autoscale_mode=on \
  --pg_num=$PG_NUM \
  --add_storages=0

# Step 3: Create the replicated pool for data
pveceph pool create "${POOL_NAME}-data" \
  --crush_rule=$CRUSH_RULE \
  --application=$APPLICATION \
  --min_size=$MIN_SIZE \
  --size=$SIZE \
  --pg_autoscale_mode=on \
  --pg_num=$PG_NUM \
  --add_storages=0
  
# Step 4: Enable Bulk mode
ceph osd pool set "${POOL_NAME}-data" bulk true

# Step 5: Create the CephFS
ceph fs new $FS_NAME "${POOL_NAME}-metadata" "${POOL_NAME}-data" --force

# Step 6: Add the storage to Proxmox
pvesm add cephfs $FS_NAME --content vztmpl,iso,backup,snippets
```

### TO DESTROY
```bash
pvesm remove $FS_NAME
ceph fs fail $FS_NAME
pveceph fs destroy $FS_NAME --remove-storages --remove-pools
ceph osd crush rule rm $CRUSH_RULE
```