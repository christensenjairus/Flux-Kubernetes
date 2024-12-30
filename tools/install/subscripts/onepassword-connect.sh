#!/bin/bash

OP_CONNECT_TOKEN=$(op item get "1Password Connect Token" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')
op read op://HomeLab\ K8S/HomeLab\ K8S\ Credentials\ File/1password-credentials.json > /tmp/1password-credentials.json

helm repo add 1password https://1password.github.io/connect-helm-charts/
helm upgrade --install connect 1password/connect --namespace onepassword-connect --create-namespace --set-file connect.credentials=/tmp/1password-credentials.json --set operator.create=true --set operator.token.value=$OP_CONNECT_TOKEN --set pollingInterval=60 #--set connect.nodeSelector.nodeclass=general --set operator.nodeSelector.nodeclass=general

rm /tmp/1password-credentials.json