### Setup instructions
* Find password from secret named `harbor-db-pguser-harbor` and place it in 1password under `Harbor DB Creds`.
```bash
kubectl get secret harbor-db-pguser-harbor -o jsonpath='{.data.password}' | base64 -d 
```
* Delete the `harbor-database-harbor` onepassword item in k8s.
* Re-apply the harbor release and harbor db creds onepassword item.
* Ensure that the new password is picked up by the harbor-core pod and connects successfully to the database.
* Login as admin
* Create line6 user
* Set line6 user as admin
* Create Docker Hub Registry using my Docker Hub credentials
* Project Quotas: 
  * library should be set to 250 GiB
* Create new project
  * Project Name: line6
  * Access Level: Private
  * Project Quota Limits: 20 GiB
  * Proxy Cache: false
* Create replication rule
  * Nginx
  * Pull-Based
  * Source Registry: Docker Hub
  * Name: library/nginx
  * Tag: latest (matching)
  * Destination NS: library
  * Flattening: Flatten All Levels
  * Trigger Mode: Scheduled
  * Cron: 0 0 * * * *
  * Bandwidth: -1
  * Override: true
* Replicate the rule manually, verify that the image shows up in the project and in minio
* Verify that you can docker login to the harbor registry
* Verify that you can pull the nginx image
* Interrogation Services: 
  * Schedule to scan all: weekly
  * 'Scan now' to scan the nginx image, verify that it works