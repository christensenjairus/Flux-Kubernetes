#!/bin/bash

# Ensure at least the backup name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 [namespaces] <name_of_backup_to_restore>"
  echo "Namespaces can be either \"*\" for all namespaces or a comma-separated list of namespaces"
  exit 1
fi

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
echo ""

# Check if the second parameter is provided (namespace)
if [ -z "$2" ]; then
  NAMESPACE="*"
  BACKUP_NAME=$1
else
  NAMESPACE=$1
  BACKUP_NAME=$2
fi

# Set restore name to include "all" if the namespace is "*"
if [ "$NAMESPACE" == "*" ]; then
  RESTORE_NAME="$current_context-all-from-$BACKUP_NAME"
else
  RESTORE_NAME="$current_context-$(echo $NAMESPACE | sed 's/*/all/g' | sed 's/,/-/g')-from-$BACKUP_NAME"
fi

echo "Creating restore of '$NAMESPACE' namespace with Velero set to restore volumes"
echo ""

velero create restore "$RESTORE_NAME" --from-backup="$BACKUP_NAME" --include-namespaces="$NAMESPACE" --restore-volumes=true  --wait