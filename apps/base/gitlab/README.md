### Setup instructions
* Wait for shared secrets job to complete
* Set the database password
```bash
./set_db_password.sh
```
* Ensure that the new password is picked up by gitlab pods and connects successfully to the database.
* Login as jchristensen via LDAP
* Upload SSH Key
* Create HomeLab group (private)
* Set homelab group icon
* Git push repos
* Set icons for repos
* Log out
* Log in as root
* Set jchristensen as admin and 'validate user account'
* Sign-Up Restrictions:
  * Sign-up enabled: off
  * Require admin approval for new sign-ups: off
  * Email confirmation settings: Hard
  * Save changes
* Change root's email to jairus@cyber-engine.com (one that's different from my ldap account)
* Confirm new email address