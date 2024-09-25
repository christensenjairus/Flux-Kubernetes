https://knowledgebase.45drives.com/kb/kb450472-intelligent-tiering-with-lifecycle-management-on-ceph-s3/

Next, install `s3cmd` and run `s3cmd --configure` to set up the connection to the Ceph cluster.

NOTE: the s3 endpoint AND the DNS Style are `<IP:PORT>`

Look over `s3-lifecycle-policy.xml` and adjust as needed. Then run the following command to apply the policy:
```bash
s3cmd setlifecycle s3-lifecycle-policy.xml s3://<bucket-name>

s3cmd info s3://<bucket-name>
```

To debug the lifecycle policy:
* Add `rgw lc debug interval = 60` to the bottom of `/etc/pve/ceph.conf`. This makes each day only 60 seconds.
* Restart the daemon on each node.

```bash
systemctl restart ceph-radosgw@rgw.`hostname -s`.service
```
