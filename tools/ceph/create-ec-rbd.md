```bash
# Variables
POOL_NAME="k8s-rbd"
APPLICATION="rbd"
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
  --add_storages=1
```

# TO DESTROY
```bash
pvesm remove $POOL_NAME
pveceph pool destroy "${POOL_NAME}-data"
pveceph pool destroy "${POOL_NAME}-metadata"
ceph osd crush rule rm $METADATA_CRUSH_RULE
ceph osd erasure-code-profile rm $ERASURE_PROFILE
```