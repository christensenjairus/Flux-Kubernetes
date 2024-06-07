# Setup Instructions

* Port-forward to admin port at port 3000
* Visit https://localhost:3000
* Set passwords
* Don't install any apps, just continue (Installation will take a while, try not to refresh the page or you'll lose the docker output)
* Once done and container is running correctly, log in as admin, go to settings and you can install the other containers as needed

Log in as admin. Access Mangegment > Authentication > OpenID > Add Config
* Set up authentication with Authelia
  * Display name: Login with Authelia
  * Logo URL: https://www.authelia.com/images/branding/logo-cropped.svg
  * Enabled: Checked
  * Auto Login: Checked
  * Hostname: Authelia
  * Default: Checked
  * Client ID: kasm
  * Client Secret: (see 1password - 'Kasm OAuth for Authelia')
  * Authorization URL: https://auth.christensencloud.us/api/oidc/authorization
  * Token URL: https://auth.christensencloud.us/api/oidc/token
  * User Info URL: https://auth.christensencloud.us/api/oidc/userinfo
  * Scope: 
    * openid
    * profile
    * groups
    * email
  * Username Attribute: preferred_username
  * Groups Attribute: groups

Access Management > Groups > Administrators > SSO Group Mappings. Add 'admin' mapping for OpenID.
Access Management > Groups > All Users > SSO Group Mappings. Add all users to this mapping for OpenID.
Logout and back in with LDAP user. Ensure you are an admin with this account.

Settings > Global > Logging > Input Splunk URL & HEC Token.
* Log host: splunk-collector.christensencloud.us
* HTTP method: POST
* Log port: 443
* Log protocol: splunk
* Disable Log Certificate Validation: false
* URL endpoint: /services/collector/event
* Minimize local logging: false
* Save and restart deployment
* Ensure the Authelia connection works before moving on

* Add these third party registries:
  * https://kasmregistry.linuxserver.io/