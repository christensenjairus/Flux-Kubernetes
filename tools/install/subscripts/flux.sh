#!/bin/bash

export GITHUB_TOKEN=$(op item get "GitHub Personal Access Token" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')

flux bootstrap github \
  --owner=christensenjairus \
  --repository=Flux-Kubernetes \
  --branch=modularize_infrastructure_with_cluster_variables \
  --path=./clusters/$current_context \
  --context=$current_context \
  --components-extra image-reflector-controller,image-automation-controller \
  --personal #\
  #--toleration-keys="node-role.kubernetes.io/control-plane"

unset GITHUB_TOKEN