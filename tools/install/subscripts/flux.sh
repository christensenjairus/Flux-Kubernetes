#!/bin/bash

# Get the current kubectl context
current_context=$(kubectl config current-context)

# Determine the branch based on the context, default to 'dev'
case $current_context in
  delta)
    branch="development"
    ;;
  epsilon)
    branch="staging"
    ;;
  omega|zeta)
    branch="production"
    ;;
  *)
    echo "Unrecognized context: $current_context. Defaulting to 'development' branch."
    branch="development"
    ;;
esac

# Fetch the GitHub token
export GITHUB_TOKEN=$(op item get "GitHub Personal Access Token" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')

# Run the flux bootstrap command with the determined branch
flux bootstrap github \
  --owner=christensenjairus \
  --repository=Flux-Kubernetes \
  --branch=$branch \
  --path=./clusters/$branch/$current_context \
  --context=$current_context \
  --components-extra image-reflector-controller,image-automation-controller \
  --personal #\
  #--toleration-keys="node-role.kubernetes.io/control-plane"

# Unset the GitHub token
unset GITHUB_TOKEN

kubectl label ns kube-system toolkit.fluxcd.io/tenant=sre-team
kubectl label ns kube-system goldilocks.fairwinds.com/enabled="true"
kubectl label ns flux-system toolkit.fluxcd.io/tenant=sre-team
kubectl label ns flux-system goldilocks.fairwinds.com/enabled="true"

echo -e "${GREEN}Add and commit the following to your cluster's flux-system kustomization in gotk-sync.yaml:"
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
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --rate-limit-interval=1m
    target:
      kind: Deployment
      name: "notification-controller"
EOF
echo -e "${NC}"