#!/bin/bash

kubectl get secret -n monitoring victoria-metrics-k8s-stack-grafana -ojsonpath='{.data.admin-password}' | base64 -d | pbcopy