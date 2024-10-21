#!/bin/bash

kubectl get secret -n grafana grafana-admin-credentials -ojsonpath='{.data.GF_SECURITY_ADMIN_PASSWORD}' | base64 -d | pbcopy