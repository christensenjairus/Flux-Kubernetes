#!/bin/bash

#pools="ceph-blockpool-2 ceph-blockpool-3"
pools="ceph-blockpool"

# Get the current kubectl context
export current_context=$(kubectl config current-context)

# Prompt the user for confirmation
echo "You are currently using the kubectl context: $current_context"
read -p "Do you want to continue with this context? (y/n) " -n 1 -r
echo    # (optional) move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Exiting script."
    exit 1
fi

echo "Continuing with context $current_context..."

for pool in $pools; do
  echo "Purging ceph trash from $pool..."
  for x in $(kubectl rook-ceph rbd list --pool $pool); do
    echo "Processing $x..."
    kubectl rook-ceph rbd snap purge $pool/$x
  done

#  ## Get all volume snapshots in a namespace
#  snap_namespace=splunk
#  for snap in $(kubectl get volumesnapshot -n $snap_namespace | egrep "k10|velero" | awk '{print $1}'); do kubectl get volumesnapshot -n $snap_namespace  $snap -o json | jq -r '.status.boundVolumeSnapshotContentName' >> $snap_namespace-snapnames.txt; done
#
#  ## Get snapshot contents for previous list of snapshots
#  for snapcontent in $(cat $snap_namespace-snapnames.txt); do kubectl get volumesnapshotcontents $snapcontent -o json | jq -r '[.metadata.name,.spec.deletionPolicy,.status.snapshotHandle] | join(" ")'; done
#
#  ## Get ceph image IDs
#  for snapcontent in $(cat $snap_namespace-snapnames.txt); do kubectl get volumesnapshotcontents $snapcontent -o json | jq -r '[.metadata.name,.spec.deletionPolicy,.status.snapshotHandle] | join(" ")' | tail -c 37 >> $snap_namespace-snaphandle-names.txt ; done
#
#  ## Patch snapcontent to allow delete
#  for snapcontent in $(cat $snap_namespace-snapnames.txt); do kubectl patch volumesnapshotcontents $snapcontent --type=merge -p '{"spec":{"deletionPolicy": "Delete"}}'; done
#
#  ## Delete VolumeSnapshot which triggers VolumeSnapshotContent deletion
#  for snap in $(kubectl get volumesnapshot -n $snap_namespace | egrep "k10|velero" | awk '{print $1}'); do kubectl delete volumesnapshot -n $snap_namespace $snap; done
done