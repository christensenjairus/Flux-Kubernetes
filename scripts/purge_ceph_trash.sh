#!/bin/bash

pools="ceph-blockpool"

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

for pool in $pools; do
  echo "Purging ceph trash from $pool..."
  for x in $(kubectl rook-ceph rbd list --pool $pool); do
    echo "Processing $x..."
    kubectl rook-ceph rbd snap purge $pool/$x
  done
done