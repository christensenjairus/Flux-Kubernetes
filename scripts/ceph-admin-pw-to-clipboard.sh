#!/bin/bash

kubectl get secret -n rook-ceph rook-ceph-dashboard-password -o json | jq '.data.password' | tr -d '"' | base64 -d | pbcopy