# Understanding Wazuh Installation
* Read [this guide](https://documentation.wazuh.com/current/deployment-options/deploying-with-kubernetes/kubernetes-deployment.html) and use it first to understand the secret generation.
* Take the certs and secrets and place them in 1password
* Change 'key: password' to 'key: credential'. (there's not a good reason for this, but credential is what the API type expects in 1password)
* Set passwords for the `admin` and `kibanaserver` users using the guide. Place in 1password and also the bcrypt hash in `./indexer_stack/wazuh-indexer/indexer_conf/internal_users.yml`
* Set passwords for the api user - make sure it has a number and a symbol. Place in 1password.

