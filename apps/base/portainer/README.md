# Setup Instructions

* Create an admin account for 'line6'
* Go to Users > Teams. Create a team called 'HomeLab'
* Go to Environments > Groups. Create a group called 'HomeLab'
* Go to Environments > Groups > HomeLab. Add access to the 'local' environment and save.
* Go to Environments > Groups > HomeLab > Manage Access.  Add 'HomeLab' to have access to this environment and save.

* Live connect to 'local' > Namespaces
  * Create namespace named 'playground'
  * Give homelab group access to 'playground' namespace

* Settings > Authentication > OAuth authentication.
  * Use SSO: ON
  * Automatic user provisioning: ON
  * Default Team: HomeLab
  * Provider: Custom
  * Client ID: portainer
  * Client Secret: <secret found in 1password - 'Portainer OAuth for Authelia'>
  * Authorization URL: https://auth.christensencloud.us/api/oidc/authorization
  * Access Token URL: https://auth.christensencloud.us/api/oidc/token
  * Resource URL: https://auth.christensencloud.us/api/oidc/userinfo
  * Redirect URL: https://portainer.christensencloud.us
  * User Identifier: preferred_username
  * Scopes: openid profile groups email
  * Save Settings

* Log out and log in with OAuth.
* Log out again and log in with the admin account.

* Go to Users > Teams. Make jchristensen the leader of the team 'HomeLab'.