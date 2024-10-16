#!/bin/bash

NAMESPACE="ingress-nginx-public"
WEBSITES="christensencloud.us|cyber-engine.com|siteclouds.net"
BASE_LOG_DIR="/audit-logs"
LOG_DIR="${BASE_LOG_DIR}/${1:-}"  # Append the passed argument as a suffix or use just the base log directory if no argument is passed
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx --output=jsonpath='{.items[0].metadata.name}')
COUNT=0

# Ensure we can exec into the ingress controller pod
if [[ -z "$POD_NAME" ]]; then
  echo "Error: Could not find the ingress controller pod."
  exit 1
fi

echo "Execing into pod $POD_NAME..."

# Command to execute inside the ingress controller to list ModSecurity logs
kubectl exec -n $NAMESPACE $POD_NAME -- bash -c "find $LOG_DIR -type f | sort | xargs grep -rE '$WEBSITES'" | \
sed 's/^[^:]*://g' | while read -r line; do
    # Ensure that only valid JSON entries are passed to jq
    if echo "$line" | grep -q '{.*}'; then
        # Process the logs with jq locally
        COUNT=$((COUNT + 1))
        echo "======================================== $COUNT ================================================="
        echo "$line" | jq -c '
          {
            timestamp: .transaction.time_stamp,
            rule_id: (.transaction.messages[].details.ruleId // "Unknown"),
            severity: (.transaction.messages[].details.severity // "Unknown"),
            maturity: (.transaction.messages[].details.maturity // "Unknown"),
            accuracy: (.transaction.messages[].details.accuracy // "Unknown"),
            client_ip: .transaction.client_ip,
            host: .transaction.request.headers.host,
            uri: .transaction.request.uri,
            data: (.transaction.messages[].details.data // "Unknown")
          }
        ' | jq
    fi
done