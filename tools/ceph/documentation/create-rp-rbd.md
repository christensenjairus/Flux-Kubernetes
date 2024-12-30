## Should probably just do this in the UI

```bash
POOL_NAME="k8s-rbd"
APPLICATION="rbd"
FAILURE_DOMAIN="osd"
DEVICE_CLASS="nvme"
MIN_SIZE=2
SIZE=2

# Step 1: Create the custom CRUSH rule for NVMe OSDs
ceph osd crush rule create-replicated $POOL_NAME \
  default \
  $FAILURE_DOMAIN \
  $DEVICE_CLASS

# Step 2: Create the replicated pool with PG count 0 and autoscaler enabled, using the custom CRUSH rule
ceph osd pool create $POOL_NAME 0 0 replicated $POOL_NAME

# Step 3: Enable autoscale for the pool
ceph osd pool set $POOL_NAME pg_autoscale_mode on

# Step 4: Set the pool size and min_size
ceph osd pool set $POOL_NAME size $SIZE
ceph osd pool set $POOL_NAME min_size $MIN_SIZE

# Step 5: Set the CRUSH rule for the pool
ceph osd pool set $POOL_NAME crush_rule $POOL_NAME

# Step 6: Set the application for the pool (e.g., RBD)
ceph osd pool application enable $POOL_NAME $APPLICATION
  
# Step 7: Add the storage to Proxmox
pvesm add rbd $POOL_NAME --pool $POOL_NAME --content images,rootdir --krbd=true
```

### TO DESTROY
```bash
POOL_NAME="k8s-rbd"
umount -f /mnt/pve/$POOL_NAME # on every host
pvesm remove $POOL_NAME
pveceph pool destroy $POOL_NAME
ceph osd crush rule rm $POOL_NAME
rm -rf /mnt/pve/$POOL_NAME # on every host
```