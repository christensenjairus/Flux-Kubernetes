# OpenLDAP (User Federation)

General Options
* UI Display Name: `OpenLdap`
* Vendor: `Other`

Connection and Authentication settings
* Connection URL: `ldap://openldap.openldap.svc.cluster.local`
* Bind DN: `cn=admin,dc=christensencloud,dc=us`
* Bind credentials: In 1Password

LDAP searching and updating
* Edit mode: `WRITEABLE`
* Users DN: `ou=users,dc=christensencloud,dc=us`

Save, then go to the User tab and ensure names appear

# OpenLDAP (Group Federation)

Go back and edit the `openldap` ldap entry from before.
Go to the `Mappers` tab and `Add Mapper`
* Name: `group`
* Mapper type: `group-ldap-mapper`
* LDAP Groups DN: `ou=groups,dc=christensencloud,dc=us`
* Group Object Classes: `groupOfNames`