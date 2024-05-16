#!/bin/bash

kubectl get secret -n rook-ceph rook-ceph-dashboard-password -ojsonpath='{.data.password}' | base64 -d | pbcopy