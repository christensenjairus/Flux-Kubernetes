#!/usr/bin/env bash

#echo -e '\nPrinting out OSD full ratio stats...\n'
#kubectl rook-ceph ceph osd dump | grep full_ratio
#
#echo -e '\nTemporarily increasing OSD Full Ratio to 98%...\n'
#kubectl rook-ceph ceph osd set-full-ratio 0.98

echo -e '\nReweighting OSDs by utilization...\n'
kubectl rook-ceph ceph osd reweight-by-utilization

echo -e '\nPrinting OSD utilization with new weights...\n'
kubectl rook-ceph ceph osd df

#echo -e '\nResetting OSD Full Ratio to 95%...\n'
#kubectl rook-ceph ceph osd set-full-ratio 0.95

echo -e '\nEnsuring Ceph Balancing Module is enabled...\n'
kubectl rook-ceph ceph balancer on

eche -e '\nDone!\n'
