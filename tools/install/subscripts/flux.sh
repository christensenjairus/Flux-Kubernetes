#!/bin/bash

export GITHUB_TOKEN=$(op item get "GitHub Personal Access Token" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')

flux bootstrap github \
  --owner=christensenjairus \
  --repository=Flux-Kubernetes \
  --branch=modularize_infrastructure_with_cluster_variables \
  --path=./clusters/dev/$current_context \
  --context=$current_context \
  --components-extra image-reflector-controller,image-automation-controller \
  --personal #\
  #--toleration-keys="node-role.kubernetes.io/control-plane"

unset GITHUB_TOKEN

echo -e "${GREEN}If not done already, add the following to your cluster's flux-system kustomization:"
echo ""
cat <<EOF
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=StrictPostBuildSubstitutions=true
    target:
      kind: Deployment
      name: "kustomize-controller"
EOF
echo -e "${NC}"