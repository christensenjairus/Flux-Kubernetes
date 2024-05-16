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

DB_USERNAME=$(op item get "GitLab DB Creds" --vault "HomeLab K8S" --format json | jq '.fields[0].value' | tr -d '"')
DB_PASSWORD=$(op item get "GitLab DB Creds" --vault "HomeLab K8S" --format json | jq '.fields[1].value' | tr -d '"')

PRAEFECT_PASSWORD=$(kubectl get secret gitlab-praefect-dbsecret -o jsonpath="{.data.secret}" | base64 --decode)

python3 ../../../scripts/set_postgrescluster_pw.py "$DB_USERNAME" "$DB_PASSWORD" gitlab gitlab-db-pguser-gitlab
python3 ../../../scripts/set_postgrescluster_pw.py "praefect" "$PRAEFECT_PASSWORD" gitlab gitlab-db-pguser-praefect
