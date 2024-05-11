#!/bin/bash

# Get all evicted pods from all namespaces
evicted_pods=$(kubectl get pods --all-namespaces --field-selector 'status.phase==Failed' -o json | jq -r '.items[] | select(.status.reason=="Evicted") | .metadata.name + " " + .metadata.namespace')

# Loop through the evicted pods and delete them
echo "$evicted_pods" | while read -r pod namespace; do
  echo "Deleting evicted pod $pod in namespace $namespace"
  kubectl delete pod "$pod" -n "$namespace"
done

echo "All evicted pods have been deleted."
