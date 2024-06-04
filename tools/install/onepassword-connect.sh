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

OP_CONNECT_TOKEN=$(op item get "1Password Connect Token" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')
op read op://HomeLab\ K8S/HomeLab\ K8S\ Credentials\ File/1password-credentials.json > /tmp/1password-credentials.json

helm repo add 1password https://1password.github.io/connect-helm-charts/
helm upgrade --install connect 1password/connect --namespace onepassword-connect --create-namespace --set-file connect.credentials=/tmp/1password-credentials.json --set operator.create=true --set operator.token.value=$OP_CONNECT_TOKEN --set pollingInterval=60 #--set connect.nodeSelector.nodeclass=general --set operator.nodeSelector.nodeclass=general

rm /tmp/1password-credentials.json