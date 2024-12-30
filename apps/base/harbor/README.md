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
  * `quay.io` (Quay) - no creds
  * `gcr.io` (docker registry)
  * `lscr.io` (docker registry)
  * `registry.developers.crunchydata.com` (docker registry)
  * `registry.gitlab.com` (docker registry)
  * `registry.k8s.io` (docker registry)
  * `us-docker.pkg.dev` (docker registry)
  * `public.ecr.aws` (docker registry)
* Create new project
  * Project Name: line6
  * Access Level: Private
  * Proxy Cache: false
* Create proxy cache projects for all registries (named the same as their URLS)
  * Enter each proxy cache project and set the policy action for retention to be `retain always`
* Verify that you can docker login to the harbor registry
* Verify that you can pull an image
* Interrogation Services: 
  * Vulnerability
    * Schedule to scan all: weekly
    * 'Scan now' to scan the nginx image, verify that it works
* Once everything is set up, you can force a cutover to using harbor's proxy registries for every new pod by running `/tools/harbor/create-harbor-pull-secret.sh`, then applying the kustomization in `/tools/harbor/policies`.

# Store TrueNAS images in case of disaster
* Create a replication rule for `library` to grab the images that are being used by TrueNAS Apps right now.
* At the time of writing these are:
  * `docker.io/minio/minio:RELEASE.2023-07-21T21-12-44Z`
  * `docker.io/plexinc/pms-docker:1.40.2.8395-c67dce28e`
  * `docker.io/tailscale/tailscale:v1.66.4`
* No need to create a schedule for these, just replicate them every time you update the TrueNAS image so you have a container as a backup.
* Flatten all levels