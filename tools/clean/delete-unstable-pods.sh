#!/bin/bash

# Function to delete pods based on status
delete_pods() {
  local namespace=$1
  echo "Checking namespace: $namespace"

  # Get pods that are not Running, Completed (Succeeded), or Unknown
  pods_to_delete=$(kubectl get pods -n "$namespace" --field-selector=status.phase!=Running,status.phase!=Succeeded,status.phase!=Unknown -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

  if [ -z "$pods_to_delete" ]; then
    echo "No pods to delete in namespace: $namespace"
  else
    echo "Deleting pods in namespace: $namespace"
    for pod in $pods_to_delete; do
      echo "Deleting pod: $pod"
      kubectl delete pod "$pod" -n "$namespace"
    done
  fi
}

# Get all namespaces in the cluster
namespaces=$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

for namespace in $namespaces; do
  delete_pods "$namespace"
done

echo "Script execution completed."
