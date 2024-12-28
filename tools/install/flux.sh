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

export GITHUB_TOKEN=$(op item get "GitHub Personal Access Token" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')

flux bootstrap github \
  --owner=christensenjairus \
  --repository=Flux-Kubernetes \
  --branch=modularize_infrastructure_with_cluster_variables \
  --path=./clusters/$current_context \
  --context=$current_context \
  --personal #\
  #--toleration-keys="node-role.kubernetes.io/control-plane"

unset GITHUB_TOKEN