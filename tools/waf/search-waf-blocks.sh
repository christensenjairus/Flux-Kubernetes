#!/bin/bash

NAMESPACE="ingress-nginx-public"
BASE_LOG_DIR="/audit-logs"
LOG_DIR="${BASE_LOG_DIR}/${1:-}"  # Append the passed argument as a suffix or use just the base log directory if no argument is passed
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx --output=jsonpath='{.items[0].metadata.name}')
COUNT=0

# Ensure we can exec into the ingress controller pod
if [[ -z "$POD_NAME" ]]; then
  echo "Error: Could not find the ingress controller pod."
  exit 1
fi

# Check if at least one search term is provided
if [[ -z "$2" ]]; then
  echo "Usage: $0 <search-term>"
  echo "Example: $0 'christensencloud.us|cyber-engine.com|siteclouds.net'"
  exit 1
fi

SEARCH_TERM=$1

echo "Execing into pod $POD_NAME and searching for '$SEARCH_TERM'..."

# Command to execute inside the ingress controller to list ModSecurity logs based on the search term
kubectl exec -n $NAMESPACE $POD_NAME -- bash -c "find $LOG_DIR -type f | sort | xargs grep -rE '$2'" | \
sed 's/^[^:]*://g' | while read -r line; do
    # Ensure that only valid JSON entries are passed to jq
    if echo "$line" | grep -q '{.*}'; then
        # Process the logs with jq locally
        COUNT=$((COUNT + 1))
        echo "======================================== $COUNT ================================================="
        echo "$line" | jq 'del(
          .transaction.response.body,
          .transaction.response.headers,
          .transaction.server_id,
          .transaction.producer.modsecurity,
          .transaction.producer.connector
        )'
    fi
done