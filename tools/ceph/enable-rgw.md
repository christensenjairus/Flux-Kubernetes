https://pve.proxmox.com/wiki/User:Grin/Ceph_Object_Gateway
https://gist.github.com/kalaspuffar/94b338168fe7200cb44b8111cb3172b3

```bash
sudo apt install radosgw -y
mkdir /etc/systemd/system/ceph-radosgw.target.wants
ln -s /lib/systemd/system/ceph-radosgw@.service /etc/systemd/system/ceph-radosgw.target.wants/ceph-radosgw@radosgw.radosgw.`hostname -s`
sudo mkdir -p /var/lib/ceph/radosgw/ceph-rgw.`hostname -s`
sudo ceph auth get-or-create client.rgw.`hostname -s` osd 'allow rwx' mon 'allow rw' -o /var/lib/ceph/radosgw/ceph-rgw.`hostname -s`/keyring
```

On one node, add the following lines to `/etc/pve/ceph.conf`
```conf
[client.rgw.Acropolis]
    host = Acropolis
    keyring = /var/lib/ceph/radosgw/ceph-rgw.Acropolis/keyring
    log file = /var/log/ceph/ceph-rgw-Acropolis.log
    rgw_frontends = beast port=8080
    rgw thread pool size = 512
    rgw_zone=default

[client.rgw.Citadel]
    host = Citadel
    keyring = /var/lib/ceph/radosgw/ceph-rgw.Citadel/keyring
    log file = /var/log/ceph/ceph-rgw-Citadel.log
    rgw_frontends = beast port=8080
    rgw thread pool size = 512
    rgw_zone=default

[client.rgw.Parthenon]
    host = Parthenon
    keyring = /var/lib/ceph/radosgw/ceph-rgw.Parthenon/keyring
    log file = /var/log/ceph/ceph-rgw-Parthenon.log
    rgw_frontends = beast port=8080
    rgw thread pool size = 512
    rgw_zone=default
```

On every host, run the following commands
```bash
sudo systemctl restart ceph-radosgw@rgw.`hostname -s`
sudo systemctl enable ceph-radosgw@rgw.`hostname -s`
sleep 3
sudo systemctl status ceph-radosgw@rgw.`hostname -s`
```

You should now be able to reach your Ceph Object Gateway at <ip>:8080

## Enable RGW in the Ceph Dashboard

https://github.com/rook/rook/issues/11169

```bash
ceph mgr module enable rgw --force
ceph config set mgr mgr/dashboard/RGW_API_SSL_VERIFY false
ceph config set mgr mgr/dashboard/RGW_API_ADMIN_RESOURCE admin

DASHBOARD_USER_ID=dashboard

radosgw-admin user create --uid=$DASHBOARD_USER_ID --display-name="Dashboard System User" --system

access_key=$(radosgw-admin user info --uid=$DASHBOARD_USER_ID | grep access_key | awk -F'"' '{print $4}')
secret_key=$(radosgw-admin user info --uid=$DASHBOARD_USER_ID | grep secret_key | awk -F'"' '{print $4}')

echo "$access_key" > access_key
echo "$secret_key" > secret_key

ceph dashboard set-rgw-api-access-key -i ./access_key
ceph dashboard set-rgw-api-secret-key -i ./secret_key

rm -f ./access_key ./secret_key

ceph mgr module disable dashboard
ceph mgr module enable dashboard
```

Create yourself a user
```bash
radosgw-admin user create --uid="<username>" --display-name="<real name>" --email="<email>"
```

Place a load balancer in front of these nodes and you're good to go.

# CLEANUP
Run on each host
```bash
sudo systemctl stop ceph-radosgw@rgw.`hostname -s`
sudo systemctl disable ceph-radosgw@rgw.`hostname -s`
sudo rm -rf /var/lib/ceph/radosgw/ceph-rgw.`hostname -s`
sudo rm -rf /etc/systemd/system/ceph-radosgw.target.wants
sudo apt purge radosgw -y
```

Run on one host
```bash
sudo ceph mgr module disable rgw
sudo ceph osd pool delete default.rgw.control default.rgw.control --yes-i-really-really-mean-it
sudo ceph osd pool delete default.rgw.log default.rgw.log --yes-i-really-really-mean-it
sudo ceph osd pool delete default.rgw.meta default.rgw.meta --yes-i-really-really-mean-it
sudo ceph osd pool delete .rgw.root .rgw.root --yes-i-really-really-mean-it
```

On one node delete the applicable lines from `/etc/pve/ceph.conf`