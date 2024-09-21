## Should probably just do this in the Ceph Dashboard

```bash
# Variables
FS_NAME="k8s-cephfs"
POOL_NAME=$FS_NAME
APPLICATION="cephfs"
ERASURE_PROFILE="${POOL_NAME}-data"
METADATA_CRUSH_RULE="${POOL_NAME}-metadata"
DEVICE_CLASS="nvme"
FAILURE_DOMAIN="osd"
MIN_SIZE=2
SIZE=2
PG_NUM=128
K=2 # Number of data chunks
M=1 # Number of coding chunks

# Step 1: Create the erasure profile
ceph osd erasure-code-profile set $ERASURE_PROFILE \
  k=$K m=$M \
  crush-failure-domain=$FAILURE_DOMAIN \
  crush-device-class=$DEVICE_CLASS

## Step 2: Create a custom CRUSH rule for NVMe OSDs (replicated, for metadata only)
ceph osd crush rule create-replicated $METADATA_CRUSH_RULE \
  default \
  $FAILURE_DOMAIN \
  $DEVICE_CLASS

# Step 3: Create the erasure-coded pool using the CRUSH rule and erasure profile
pveceph pool create $POOL_NAME \
  --erasure-coding k=$K,m=$M,profile=$ERASURE_PROFILE \
  --crush_rule=$METADATA_CRUSH_RULE \
  --application=$APPLICATION \
  --min_size=$MIN_SIZE \
  --size=$SIZE \
  --pg_autoscale_mode=on \
  --pg_num=$PG_NUM \
  --add_storages=0

# Step 4: Allow EC overwrites and bulk mode
ceph osd pool set "${POOL_NAME}-data" allow_ec_overwrites true
ceph osd pool set vm-cephfs-data bulk true

# Step 5: Create the CephFS
ceph fs new $FS_NAME "${POOL_NAME}-metadata" "${POOL_NAME}-data" --force

# Step 6: Add the storage to Proxmox
pvesm add cephfs $FS_NAME --content vztmpl,iso,backup,snippets --pool "${POOL_NAME}-metadata" --data-pool "${POOL_NAME}-data"
```

### TO DESTROY
```bash
pvesm remove $FS_NAME
ceph fs fail $FS_NAME
pveceph fs destroy $FS_NAME --remove-storages --remove-pools
ceph osd crush rule rm $METADATA_CRUSH_RULE
ceph osd erasure-code-profile rm $ERASURE_PROFILE
```