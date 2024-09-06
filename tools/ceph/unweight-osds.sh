#!/usr/bin/env bash

echo -e '\nReweighting all OSDs to 1.00000...\n'
for osd_id in $(kubectl rook-ceph ceph osd df | grep hdd | awk '$4 != 1.00000 {print $1}'); do
  kubectl rook-ceph ceph osd reweight "${osd_id}" 1.0
done

echo -e '\nPrinting OSD utilization with new weights...\n'
kubectl rook-ceph ceph osd df

echo -e '\nEnsuring Ceph Balancing Module is enabled...\n'
kubectl rook-ceph ceph balancer on

eche -e '\nDone!\n'
