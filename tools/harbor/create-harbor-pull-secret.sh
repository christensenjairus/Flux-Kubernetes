#!/bin/bash

# Get the current kubectl context
current_context=$(kubectl config current-context)

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

HARBOR_USERNAME=$(op item get "Harbor (line6)" --vault "HomeLab K8S" --format json | jq '.fields[0].value' | tr -d '"')
HARBOR_PASSWORD=$(op item get "Harbor (line6)" --vault "HomeLab K8S" --format json | jq '.fields[1].value' | tr -d '"')
HARBOR_URL=$(op item get "Harbor (line6)" --vault "HomeLab K8S" --format json | jq '.fields[3].value' | tr -d '"')
HARBOR_EMAIL=$(op item get "Harbor (line6)" --vault "HomeLab K8S" --format json | jq '.fields[4].value' | tr -d '"')

echo HARBOR_USERNAME=$HARBOR_USERNAME
echo HARBOR_PASSWORD=$HARBOR_PASSWORD
echo HARBOR_URL=$HARBOR_URL
echo HARBOR_EMAIL=$HARBOR_EMAIL

# Loop through all namespaces with the specified label
for ns in $(kubectl get ns -l toolkit.fluxcd.io/tenant=dev-team -o jsonpath="{.items[*].metadata.name}"); do

  kubectl delete secret -n $ns harbor-pull-secret 2>/dev/null
  kubectl create secret docker-registry harbor-pull-secret \
    --namespace=$ns \
    --docker-username=$HARBOR_USERNAME \
    --docker-password=$HARBOR_PASSWORD \
    --docker-server=$HARBOR_URL \
    --docker-email=$HARBOR_EMAIL

done