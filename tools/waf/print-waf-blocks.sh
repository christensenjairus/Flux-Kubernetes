#!/bin/bash

NAMESPACE="ingress-nginx-public"
LOG_DIR="/audit-logs/20241016"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx --output=jsonpath='{.items[0].metadata.name}')

# Ensure we can exec into the ingress controller pod
if [[ -z "$POD_NAME" ]]; then
  echo "Error: Could not find the ingress controller pod."
  exit 1
fi

echo "Execing into pod $POD_NAME..."

# Command to execute inside the ingress controller to list ModSecurity logs
kubectl exec -n $NAMESPACE $POD_NAME -- bash -c "grep -rE 'christensencloud.us|cyber-engine.com|siteclouds.net' $LOG_DIR" | \
sed 's/^[^:]*://g' | while read -r line; do
    # Ensure that only valid JSON entries are passed to jq
    if echo "$line" | grep -q '{.*}'; then
        # Process the logs with jq locally
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
        '
    fi
done #| awk '
#    BEGIN {
#      # Print column headers
#      printf("%-10s %-15s %-40s %-30s\n", "Count", "Rule ID", "Source IP", "URI")
#    }
#    {
#      count[$2]++;
#      ruleId[$2]=$2;
#      client_ip[$2]=$3;
#      uri[$2]=$4;
#    }
#    END {
#      for (id in count) {
#        printf("%-10s %-15s %-40s %-30s\n", count[id], ruleId[id], client_ip[id], uri[id])
#      }
#    }'