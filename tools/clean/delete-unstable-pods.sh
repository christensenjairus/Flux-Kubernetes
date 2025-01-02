#!/bin/bash

# Function to delete pods based on status
delete_pods() {
  local namespace=$1
  echo "Checking namespace: $namespace"

  # Get pods in Unknown state using kubectl and jq
  pods_in_unknown_state=$(kubectl get pods -n "$namespace" -o json | jq -r '
    .items[] |
    select(.status.containerStatuses != null) |
    select(.status.containerStatuses[].state.terminated != null and .status.containerStatuses[].state.terminated.reason == "Unknown") |
    .metadata.name
  ')

  # Get pods that are not Running or Succeeded
  other_pods_to_delete=$(kubectl get pods -n "$namespace" --field-selector=status.phase!=Running,status.phase!=Succeeded,status.phase!=Pending -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

  # Combine both lists of pods to delete
  pods_to_delete=$(echo -e "$pods_in_unknown_state\n$other_pods_to_delete" | sort | uniq)

  if [ -z "$pods_to_delete" ]; then
    echo "No pods to delete in namespace: $namespace"
  else
    echo "Deleting pods in namespace: $namespace"
    for pod in $pods_to_delete; do
      echo "Deleting pod: $pod"
      kubectl delete pod "$pod" -n "$namespace" --grace-period=0 --force
    done
  fi
}

# Get all namespaces in the cluster
namespaces=$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

for namespace in $namespaces; do
  delete_pods "$namespace"
done

echo "Script execution completed."