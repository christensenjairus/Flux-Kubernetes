#!/bin/bash

# Ensure a namespace is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <namespaces>"
  echo "Namespaces can be either \"*\" for all namespaces or a comma-separated list of namespaces"
  exit 1
fi

# Get the current kubectl context
export current_context=$(kubectl config current-context)

# Prompt the user for confirmation
echo "You are currently using the kubectl context: $current_context"
read -p "Do you want to continue with this context? (y/n) " -n 1 -r
echo    # (optional) move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting script."
    exit 1
fi

echo "Continuing with context $current_context..."
echo ""

NAMESPACE=$1

# Set backup name to include "all" if the namespace is "*"
if [ "$NAMESPACE" == "*" ]; then
  BACKUP_NAME="$current_context-all-$(date +'%Y-%m-%d-%H-%M-%S')"
else
  # Replace '*' with 'all' and ',' with '-'
  BACKUP_NAME="$current_context-$(echo $NAMESPACE | sed 's/*/all/g' | sed 's/,/-/g')-$(date +'%Y-%m-%d-%H-%M-%S')"
fi

echo "Creating backup of '$NAMESPACE' namespace(s) with Velero set to backup volumes, move data, and have a ttl of 7d"
echo ""

velero create backup "$BACKUP_NAME" --include-namespaces="$NAMESPACE" --snapshot-volumes=true --snapshot-move-data=true --ttl=168h0m0s --csi-snapshot-timeout=1h0m0s --wait