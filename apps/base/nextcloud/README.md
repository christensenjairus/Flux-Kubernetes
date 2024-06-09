# Setup Instructions
* Install Apps
  * Brute force settings (Featured)
  * Suspicious Login (Featured)
  * Camera RAW Previews (Files)
  * EPUB Viewer (Files)
  * Preview Generator (Files)
  * OpenID Connect Login (Integration)
* Set the Theme
  * Name: ChristensenCloud
  * Web Link: https://christensencloud.us
  * Slogan: Friends and Family Cloud
  * Color: #205187
  * Logo: Upload (Icons/Christensen-White)
  * Background Login Image: Upload (Landscapes/68)
  * Header Logo: Upload (Monogram-C/C)
  * Favicon: Upload (Monogram-C/C)
  * Disable User Theming: True
* Sharing
  * 'Privacy Settings for Sharing'
    * Checked -> 'Allow username autocompletion to users within the same groups and limit system address books to users in the same groups'
  * 'Default Share Permissions'
    * Uncheck all
  * Federated Cloud Sharing
    * Uncheck all
* Create Groups
  * `nextcloud-everyone` # (default)
  * `nextcloud-christensen` (ldap)
  * `nextcloud-lundin` (ldap)
* Follow the 'Migrate User Data' instructions for `jchristensen`
* Share family folders with the appropriate groups (allow only to download, read, and share)
  * `Christensen Family Shared Folder` -> `nextcloud-christensen`
  * `Lundin Family Shared Folder` -> `nextcloud-lundin`
  * `Jairus' Photos` -> `megan`
* Migrate other users and ensure that the shared folders appear when they first log in

# Migrate User Data
  * Get into the user data and `mv` the users folder to `<username>-bak`
  * Let the user log in
  * `cp -r` the data from `<username>-bak/files/*` to `<username>/files/`
  * Run `./scan_files.sh <username>` to discover the new files
  * Run `./generate_previews.sh <username>` to generate thumbnails for their files
  * Let the user refresh the page & their files should be there
  * Delete `<username>-bak` when you're sure everything is working