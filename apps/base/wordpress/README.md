# Restore Instructions
[//]: # (* When restoring, **you must drop the replicaCount to 1** so that only one wordpress instance is setting up the database and installation files.)
* Log in as line6
* Install & Activate 'Updraft Plus' plugin
* Create backup storage location in Updraft Plus settings
  * Remote storage type: S3-Compatible (Generic)
  * S3 Access Key: minio
  * S3 Secret Key: (in 1Password)
  * S3 Location: <bucket-name>
  * S3 Endpoint: https://nas3.christensencloud.us
  * Bucket Access Style: Path Style
  * Save
* Scan for past backups in Updraft 'Backup/Restore' page
* Restore everything except plugins from the most recent complete backup
  * Doing plugins separately has worked more smoothly for me in the past. You don't want to overwrite the settings for the plugin that is restoring the backup!
  * If a login box appears before the restore is complete, exit it
* Restore plugins from most recent complete backup
* 'Delete old folders'

[//]: # (* Raise it back to **3** replicas)

# Initial Setup Instructions
[//]: # (* When it first installs, **you must drop the replicaCount to 1** so that only one wordpress instance is setting up the database and installation files.)
[//]: # (* Don't touch the mariadb pods when first running. The warning about 'Failed to load slave replication state' is just a warning and will be fixed.)
* Log in as line6
* Update WordPress and plugins
* Install & enable these plugins
  * Updraft Plus
  * Easy Updates Manager
* Disable and delete these plugins
  * Hello Dolly
  * All-In-One Migration
* Set up 'Updraft Plus' plugin, like it says in the 'restore' instructions
  * Also, set these settings:
    * Files Backup Schedule: Daily - 14 days
    * Database Backup Schedule: Daily - 14 days
    * Send emails after backups: Enabled
    * Show Expert Settings:
      * Delete local backup (keep only in s3)
* Set up 'Easy Updates Manager' plugin to 'Auto Update Everything'
* Set up Akismet account with API Key (in 1password)
* Set up Jetpack
* Set WP Mail SMTP from name to the name of the website & test
* Delete non-active themes
* Add 2FA to the admin account

[//]: # (* Set up W3 Total Cache Plugin)
[//]: # (  * Run through the 'Setup Guide', choosing the fastest option when possible)
[//]: # (  * Skip the 'Setup Guide')
[//]: # (  * Go to 'General Settings', enabling caching with memcached where available &#40;Page, Minify, Database, Object&#41;)
[//]: # (  * Image optimization: Enabled)
[//]: # (  * Lazy loading: Enabled)
[//]: # (  * Save & purge caches)
[//]: # (  * You will need to set the Memcached url in some places in the general settings, it should warn you where. The memcached url looks like this: `<release_name>-memcached.<namespace>.svc:11211`)
[//]: # (* Raise it back to **3** replicas)

# Things to Change to 'Make it Bigger'
The reason I'm not going with this approach is that the RWX has too much latency, causing basic things like restores to crash. Even with a single wordpress pod, it has issues with speed, regardless of memcached. For example, deleting the 'old' folders after a restore takes so long that my webpage times out while with RWO it takes 3 seconds. Another example is that the 'Setup Guide' on for W3 Caching can't complete a database test because the disk is so slow.
1. Replace ReadWriteMany with ReadWriteOnce for WordPress
2. Replace 'ceph-block' with 'ceph-filesystem' for WordPress
3. Set wordpress to 3 replicas
4. Change to commented out rollingUpdate strategy for wordpress
5. Enable memcached
6. Change memcached to replication
7. Set memcached to 3 replicas
8. Change to commented out rollingUpdate strategy for memcached
9. Change mariadb to replication