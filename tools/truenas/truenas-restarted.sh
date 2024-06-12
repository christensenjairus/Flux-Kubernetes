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

kubectl rollout restart deploy,sts,ds,job,cronjob -n democratic-csi-nfs
kubectl rollout restart deploy,sts,ds,job,cronjob -n democratic-csi-iscsi
kubectl rollout restart deploy,sts,ds,job,cronjob -n media
kubectl rollout restart deploy,sts,ds,job,cronjob -n nextcloud
