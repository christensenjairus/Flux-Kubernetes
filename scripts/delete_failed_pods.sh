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

# Get all evicted pods from all namespaces
evicted_pods=$(kubectl get pods --all-namespaces --field-selector 'status.phase==Failed' -o json | jq -r '.items[] | select(.status.phase=="Failed") | .metadata.name + " " + .metadata.namespace')

# Loop through the evicted pods and delete them
echo "$evicted_pods" | while read -r pod namespace; do
  echo "Deleting failed pod $pod in namespace $namespace"
  kubectl delete pod "$pod" -n "$namespace"
done

echo "All evicted pods have been deleted."
