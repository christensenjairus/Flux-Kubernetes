#!/bin/bash

kubectl get secret -n monitoring victoria-metrics-k8s-stack-grafana -o json | jq '.data."admin-password"' | tr -d '"' | base64 -d | pbcopy