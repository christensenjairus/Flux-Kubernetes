### Setup instructions
* Set the database password
```bash
./set_db_password.sh
```
* Ensure that the new password is picked up by new harbor-core pods and connects successfully to the database.
```bash
kubectl rollout restart -n harbor deployment harbor-core
kubectl rollout restart -n harbor deployment harbor-jobservice
```
* Login as admin
* Create line6 user
* Set line6 user as admin
* Add registries (named the same as their urls, with no quotas)
  * `docker.io` (Docker Hub) - docker creds
  * `ghcr.io` (GHCR) - no creds
  * `gcr.io` (GCR) - no creds
  * `quay.io` (Quay) - no creds
  * `lscr.io` (docker registry)
  * `registry.developers.crunchydata.com` (docker registry)
  * `registry.gitlab.com` (docker registry)
  * `registry.k8s.io` (docker registry)
  * `us-docker.pkg.dev` (docker registry)
* Create new project
  * Project Name: line6
  * Access Level: Private
  * Proxy Cache: false
* Create proxy cache projects for all registries (named the same as their URLS)
* Verify that you can docker login to the harbor registry
* Verify that you can pull an image
* Interrogation Services: 
  * Vulnerability
    * Schedule to scan all: weekly
    * 'Scan now' to scan the nginx image, verify that it works
