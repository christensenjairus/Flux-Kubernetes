## Should probably just do this in the UI

```bash
# Variables
POOL_NAME="k8s-rbd"
APPLICATION="rbd"
DEVICE_CLASS="nvme"
FAILURE_DOMAIN="osd"
MIN_SIZE=2
SIZE=2
PG_NUM=128

# Step 1: Create a custom CRUSH rule for NVMe OSDs (replicated)
ceph osd crush rule create-replicated $POOL_NAME \
  default \
  $FAILURE_DOMAIN \
  $DEVICE_CLASS

# Step 2: Create the replicated pool using the CRUSH rule
pveceph pool create $POOL_NAME \
  --crush_rule=$POOL_NAME \
  --application=$APPLICATION \
  --min_size=$MIN_SIZE \
  --size=$SIZE \
  --pg_autoscale_mode=on \
  --pg_num=$PG_NUM \
  --add_storages=0
  
# Step 6: Add the storage to Proxmox
pvesm add rbd $POOL_NAME --pool $POOL_NAME --content images,rootdir --krbd=true
```

### TO DESTROY
```bash
pvesm remove $POOL_NAME
pveceph pool destroy $POOL_NAME
ceph osd crush rule rm $POOL_NAME
```