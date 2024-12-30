
You can `mkdir` in any cephfs directory under `mkdir .snap/<snapshot_name>` to automatically create a snapshot of that folder and all child folders.

Like this:
```bash
FS_NAME="pve-file"
SUBFOLDER="/" # ensure the pre-pended slash exists
mkdir "/mnt/pve/${FS_NAME}${SUBFOLDER}/.snap/$(date +%Y%m%d-%Hh%M)"
```

To enable automatic snapshots and snapshot retention...

You should do this per filesystem.

https://www.pivert.org/cephfs-snapshots/
```bash
FS_NAME="pve-file" # you could do / for the root, but I don't know how it will behave with multiple filesystems.
ceph mgr module enable snap_schedule
ceph fs snap-schedule add "${FS_NAME}" 1h
ceph fs snap-schedule activate "${FS_NAME}"
ceph fs snap-schedule retention add "${FS_NAME}" m 12
ceph fs snap-schedule retention add "${FS_NAME}" w 4
ceph fs snap-schedule retention add "${FS_NAME}" d 7
ceph fs snap-schedule retention add "${FS_NAME}" h 24
ceph fs snap-schedule status "${FS_NAME}" | jq
```

To do the reverse...

```bash
FS_NAME="pve-files"
ceph fs snap-schedule deactivate "${FS_NAME}"
ceph fs snap-schedule remove "${FS_NAME}"
```