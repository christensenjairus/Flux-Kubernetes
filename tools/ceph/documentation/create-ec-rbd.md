## Should probably just do this in the Ceph Dashboard

```bash
POOL_NAME="vm-rbd"
APPLICATION="rbd"
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
ceph osd pool create $POOL_NAME 0 0 erasure $ERASURE_PROFILE

# Step 4: Enable autoscale for the pool
ceph osd pool set $POOL_NAME pg_autoscale_mode on

# Step 5: Set the pool size and min_size
ceph osd pool set $POOL_NAME size $SIZE
ceph osd pool set $POOL_NAME min_size $MIN_SIZE

# Step 6: Set the application for the pool
ceph osd pool application enable $POOL_NAME $APPLICATION

# Step 7: (Optional) Add the storage to Proxmox
# pvesm add rbd $POOL_NAME --content images,rootdir --krbd=true
```

### TO DESTROY
```bash
POOL_NAME="vm-rbd"
ERASURE_PROFILE="${POOL_NAME}-data"
METADATA_CRUSH_RULE="${POOL_NAME}-metadata"
umount -f /mnt/pve/$POOL_NAME # on every host
pvesm remove $POOL_NAME
pveceph pool destroy "${POOL_NAME}-data"
pveceph pool destroy "${POOL_NAME}-metadata"
ceph osd crush rule rm $METADATA_CRUSH_RULE
ceph osd erasure-code-profile rm $ERASURE_PROFILE
rm -rf /mnt/pve/$POOL_NAME # on every host
```