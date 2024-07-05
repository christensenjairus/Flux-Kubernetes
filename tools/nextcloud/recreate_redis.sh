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

echo "Deleting the Redis deployment..."
helm uninstall -n nextcloud nextcloud-redis
kubectl delete -n nextcloud hr nextcloud-redis

echo "Deleting the Redis PVCs..."
kubectl get pvc -n nextcloud --no-headers | grep 'redis' | awk '{print $1}' | xargs kubectl delete pvc -n nextcloud

echo "Sleeping for 60 seconds to allow the PVCs to be deleted..."
sleep 60s

echo "Reconciling the cluster apps to recreate the Redis deployment..."
flux reconcile kustomization apps
