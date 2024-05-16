### Setup instructions
* Set the database password
```bash
./set_db_password.sh
```
* Ensure that the new password is picked up by gitlab pods and connects successfully to the database.
* Login as root
* Change root's email to jairus@cyber-engine.com (one that's different from my ldap account)
* Sign-Up Restrictions:
  * Sign-up enabled: off
  * Require admin approval for new sign-ups: off
  * Email confirmation settings: Hard