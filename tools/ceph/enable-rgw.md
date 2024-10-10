https://pve.proxmox.com/wiki/User:Grin/Ceph_Object_Gateway
https://gist.github.com/kalaspuffar/94b338168fe7200cb44b8111cb3172b3
https://danielpersson.dev/2022/01/03/how-to-setup-a-rados-gateway-for-an-s3-api-in-ceph/
https://github.com/rook/rook/issues/11169

```bash
apt install radosgw -y
mkdir /etc/systemd/system/ceph-radosgw.target.wants
ln -s /lib/systemd/system/ceph-radosgw@.service /etc/systemd/system/ceph-radosgw.target.wants/ceph-radosgw@radosgw.radosgw.`hostname -s`
mkdir -p /var/lib/ceph/radosgw/ceph-rgw.`hostname -s`
ceph auth get-or-create client.rgw.`hostname -s` osd 'allow rwx' mon 'allow rw' -o /var/lib/ceph/radosgw/ceph-rgw.`hostname -s`/keyring
```

On one node, add the following lines to `/etc/pve/ceph.conf`
```conf
[client.rgw.Acropolis]
    host = Acropolis
    keyring = /var/lib/ceph/radosgw/ceph-rgw.Acropolis/keyring
    log_file = /var/log/ceph/ceph-rgw-Acropolis.log
    rgw_frontends = beast port=8080
    rgw_thread_pool_size = 1024
    rgw_cache_enabled = true
    rgw_cache_lru_size = 1000000
    rgw_dns_name = s3.christensencloud.us
    rgw_trust_forwarded_https = true
    rgw_zone = default

[client.rgw.Citadel]
    host = Citadel
    keyring = /var/lib/ceph/radosgw/ceph-rgw.Citadel/keyring
    log_file = /var/log/ceph/ceph-rgw-Citadel.log
    rgw_frontends = beast port=8080
    rgw_thread_pool_size = 1024
    rgw_cache_enabled = true
    rgw_cache_lru_size = 1000000
    rgw_dns_name = s3.christensencloud.us
    rgw_trust_forwarded_https = true
    rgw_zone = default
    
[client.rgw.Parthenon]
    host = Parthenon
    keyring = /var/lib/ceph/radosgw/ceph-rgw.Parthenon/keyring
    log_file = /var/log/ceph/ceph-rgw-Parthenon.log
    rgw_frontends = beast port=8080
    rgw_thread_pool_size = 1024
    rgw_cache_enabled = true
    rgw_cache_lru_size = 1000000
    rgw_dns_name = s3.christensencloud.us
    rgw_trust_forwarded_https = true
    rgw_zone = default
```

On every host, run the following commands
```bash
systemctl restart ceph-radosgw@rgw.`hostname -s`
systemctl enable ceph-radosgw@rgw.`hostname -s`
sleep 3
systemctl status ceph-radosgw@rgw.`hostname -s`
```

You should now be able to reach your Ceph Object Gateway at <ip>:8080

Create a new zone, zonegroup, and realm
```bash
radosgw-admin realm create --rgw-realm=us-west --default
radosgw-admin zonegroup create --rgw-zonegroup=us --endpoints=http://10.0.0.100:8080,http://10.0.0.108:8080,http://10.0.0.109:8080 --rgw-realm=us-west --master --default
radosgw-admin zone create --rgw-zonegroup=us --endpoints=http://10.0.0.100:8080,http://10.0.0.108:8080,http://10.0.0.109:8080 --rgw-zone=us-west-1 --master --default

radosgw-admin zonegroup remove --rgw-zonegroup=default --rgw-zone=default
radosgw-admin period update --commit
radosgw-admin zone delete --rgw-zone=default
radosgw-admin period update --commit
radosgw-admin zonegroup delete --rgw-zonegroup=default
radosgw-admin period update --commit

sed -i 's/rgw_zone = default/rgw_zone = us-west-1/' /etc/pve/ceph.conf
```

On every host, restart the daemon
```bash
systemctl restart ceph-radosgw@rgw.`hostname -s`
systemctl enable ceph-radosgw@rgw.`hostname -s`
sleep 3
systemctl status ceph-radosgw@rgw.`hostname -s`
```

Delete default pools and create a zone synchronization user
```bash
ceph osd pool delete default.rgw.control default.rgw.control --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.log default.rgw.log --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.meta default.rgw.meta --yes-i-really-really-mean-it

SYNC_USER_ID=zone-synchronization-user
radosgw-admin user create --uid="zone-synchronization-user" --display-name="Zone Synchronization User" --system

access_key=$(radosgw-admin user info --uid=$SYNC_USER_ID | grep access_key | awk -F'"' '{print $4}')
secret_key=$(radosgw-admin user info --uid=$SYNC_USER_ID | grep secret_key | awk -F'"' '{print $4}')

radosgw-admin zone modify --rgw-zone=us-west-1 --access-key=$access_key --secret=$secret_key
radosgw-admin period update --commit
```

Create your standard-ia storage placement group
```bash
# Add a placement group for standard-ia
radosgw-admin zonegroup placement add \
--rgw-zonegroup us \
--placement-id default-ia-placement \
--storage-class STANDARD_IA

# Add the pools for STANDARD
radosgw-admin zone placement modify \
--rgw-zone us-west-1 \
--placement-id default-placement \
--storage-class STANDARD \
--data-pool us-west-1.rgw.buckets.standard.data \
--data_extra_pool us-west-1.rgw.buckets.standard.non-ec \
--index-pool us-west-1.rgw.buckets.standard.index \
--compression none

# Add the pools for STANDARD_IA
radosgw-admin zone placement add \
--rgw-zone us-west-1 \
--placement-id default-ia-placement \
--storage-class STANDARD_IA \
--data-pool us-west-1.rgw.buckets.standard-ia.data \
--data_extra_pool us-west-1.rgw.buckets.standard-ia.non-ec \
--index-pool us-west-1.rgw.buckets.standard-ia.index \
--compression lz4

radosgw-admin period update --commit
```

Create your data pools
* `us-west-1.rgw.buckets.standard.data`
  ```bash
  ceph osd crush rule create-replicated rgw-standard-data default osd nvme
  ceph osd pool create us-west-1.rgw.buckets.standard.data 0 0 replicated rgw-standard-data
  ceph osd pool set us-west-1.rgw.buckets.standard.data size 3
  ceph osd pool set us-west-1.rgw.buckets.standard.data pg_autoscale_mode on
  ceph osd pool application enable us-west-1.rgw.buckets.standard.data rgw
  ceph osd pool set us-west-1.rgw.buckets.standard.data compression_mode passive
  ceph osd pool set us-west-1.rgw.buckets.standard.data compression_algorithm lz4
  ```

* `us-west-1.rgw.buckets.standard-ia.data`
  ```bash
  ceph osd erasure-code-profile set rgw-standard-ia-data \
    k=2 m=1 \
    crush-failure-domain=host \
    crush-root=default \
    plugin=jerasure \
    technique=reed_sol_van \
    stripe_unit=4096
  ceph osd pool create us-west-1.rgw.buckets.standard-ia.data 0 0 erasure rgw-standard-ia-data
  ceph osd pool set us-west-1.rgw.buckets.standard-ia.data pg_autoscale_mode on
  ceph osd pool application enable us-west-1.rgw.buckets.standard-ia.data rgw
  ceph osd pool set us-west-1.rgw.buckets.standard-ia.data compression_mode force
  ceph osd pool set us-west-1.rgw.buckets.standard-ia.data compression_algorithm lz4
  ceph osd pool set us-west-1.rgw.buckets.standard-ia.data allow_ec_overwrites true
  ```

Create yourself a user
```bash
MY_USER=line6
radosgw-admin user create --uid=$MY_USER --display-name="<real name>" --email="<email>"
access_key=$(radosgw-admin user info --uid=$MY_USER | grep access_key | awk -F'"' '{print $4}')
secret_key=$(radosgw-admin user info --uid=$MY_USER | grep secret_key | awk -F'"' '{print $4}')
echo "Your access Key: $access_key" 
echo "Your secret Key: $secret_key"

s3cmd --configure # set up a connection to the Ceph cluster
# NOTE: the s3 endpoint AND the DNS Style are the hostname (with optional port)
```

Create a bucket and apply a lifecycle policy
```bash
BUCKET_NAME=backups
s3cmd mb s3://$BUCKET_NAME # Add -P to make it publicly readable
s3cmd setversioning s3://$BUCKET_NAME enable # Enable versioning

# Review the lifecycle policy and adjust as needed
s3cmd setlifecycle s3-lifecycle-policy.xml s3://$BUCKET_NAME

s3cmd info s3://$BUCKET_NAME
```

If you need to debug the lifecycle policy
* Add `rgw lc debug interval = 60` to the bottom of `/etc/pve/ceph.conf`. This makes each day last only 60 seconds.
* Restart the daemon on each node. (systemctl restart ceph-radosgw@rgw.`hostname -s`.service)

## Enable RGW in the Ceph Dashboard

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

Place a load balancer in front of these nodes and you're good to go!

# CLEANUP
Run on each host
```bash
systemctl stop ceph-radosgw@rgw.`hostname -s`
systemctl disable ceph-radosgw@rgw.`hostname -s`
rm -rf /var/lib/ceph/radosgw/ceph-rgw.`hostname -s`
rm -rf /etc/systemd/system/ceph-radosgw.target.wants
apt purge radosgw -y
```

Run on one host
```bash
ceph mgr module disable rgw
ceph osd pool delete .rgw.root .rgw.root --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.control default.rgw.control --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.log default.rgw.log --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.meta default.rgw.meta --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.log default.rgw.log --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.buckets.non-ec default.rgw.buckets.non-ec --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.buckets.index default.rgw.buckets.index --yes-i-really-really-mean-it
ceph osd pool delete default.rgw.buckets.data default.rgw.buckets.data --yes-i-really-really-mean-it

ceph osd pool delete us-west-1.rgw.control us-west-1.rgw.control --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.log us-west-1.rgw.log --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.meta us-west-1.rgw.meta --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.non-ec us-west-1.rgw.buckets.non-ec --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.index us-west-1.rgw.buckets.index --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.data us-west-1.rgw.buckets.data --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.standard.index us-west-1.rgw.buckets.standard.index --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.standard.data us-west-1.rgw.buckets.standard.data --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.standard-ia.index us-west-1.rgw.buckets.standard-ia.index --yes-i-really-really-mean-it
ceph osd pool delete us-west-1.rgw.buckets.standard-ia.data us-west-1.rgw.buckets.standard-ia.data --yes-i-really-really-mean-it

ceph osd erasure-code-profile rm rgw-standard-ia-data
ceph osd crush rule rm rgw-standard-data

sed -i 's/rgw_zone = us-west-1/rgw_zone = default/' /etc/pve/ceph.conf
```
