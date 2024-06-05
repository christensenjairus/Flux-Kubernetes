#!/bin/bash

# Get the current kubectl context
current_context=$(kubectl config current-context)

# Prompt the user for confirmation
echo "You are currently using the kubectl context: $current_context"
read -p "Do you want to continue with this context? (y/n) " -n 1 -r
echo    # (optional) move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Exiting script."
    exit 1
fi

echo "Continuing with context $current_context..."

DB_USERNAME=$(op item get "Authelia DB Creds" --vault "HomeLab K8S" --format json | jq '.fields[0].value' | tr -d '"')
DB_PASSWORD=$(op item get "Authelia DB Creds" --vault "HomeLab K8S" --format json | jq '.fields[1].value' | tr -d '"')

echo "DB_USERNAME is $DB_USERNAME"
echo "DB_PASSWORD is $DB_PASSWORD"

python3 ../../../tools/helpers/set_postgrescluster_pw.py "$DB_USERNAME" "$DB_PASSWORD" authelia authelia-db-pguser-authelia
