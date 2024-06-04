#!/bin/bash

# Get the current kubectl context
export current_context=$(kubectl config current-context)

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

kubectl get onepassworditem -n authelia authelia-config -o yaml > /tmp/authelia-config.yaml
kubectl delete secret -n authelia authelia-config
kubectl delete onepassworditem -n authelia authelia-config
kubectl apply -f /tmp/authelia-config.yaml
rm /tmp/authelia-config.yaml

sleep 2

kubectl rollout restart deploy -n authelia authelia