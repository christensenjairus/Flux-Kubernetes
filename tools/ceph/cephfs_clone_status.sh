#!/bin/bash

# Define colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Ensure that the script takes two arguments: namespace and PVC name
if [ $# -ne 2 ]; then
  echo -e "${GREEN}Usage: $0 <namespace> <persistent-volume-claim-name>${NC}"
  exit 1
fi

NAMESPACE=$1
PVC_NAME=$2

echo -e "${GREEN}Namespace: $NAMESPACE${NC}"
echo -e "${GREEN}PVC Name: $PVC_NAME${NC}"

# Find the Persistent Volume associated with the PVC
PV_NAME=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" --output=jsonpath='{.spec.volumeName}')
if [ -z "$PV_NAME" ]; then
  echo -e "\n${GREEN}Error: Could not find PV associated with PVC $PVC_NAME in namespace $NAMESPACE${NC}"
  exit 1
fi

echo -e "${GREEN}Found PV name: $PV_NAME${NC}"

# Extract the subvolume name from the PV spec
SUBVOL_NAME=$(kubectl get pv "$PV_NAME" --output=jsonpath='{.spec.csi.volumeAttributes.subvolumeName}')
if [ -z "$SUBVOL_NAME" ]; then
  echo -e "\n${GREEN}Error: Could not retrieve subvolume name from PV $PV_NAME${NC}"
  exit 1
fi

echo -e "\n${GREEN}Found subvolume name: $SUBVOL_NAME${NC}"

# Determine the Ceph volume name based on the PV storageclass or CSI driver type
VOLUME_NAME=$(kubectl get pv "$PV_NAME" --output=jsonpath='{.spec.storageClassName}')
if [ -z "$VOLUME_NAME" ]; then
  echo -e "\n${GREEN}Error: Could not determine the storageclass (aka ceph volume) from PV $PV_NAME${NC}"
  exit 1
fi

echo -e "\n${GREEN}Determined storageclass (ceph volume): $VOLUME_NAME${NC}"

# Get the list of snapshots for the subvolume
echo -e "\n${GREEN}Retrieving snapshots for subvolume: $SUBVOL_NAME${NC}"

SNAPSHOTS=$(kubectl rook-ceph ceph fs subvolume snapshot ls "$VOLUME_NAME" "$SUBVOL_NAME" --group_name csi --format json | jq -r '.[] | .name')

if [ -z "$SNAPSHOTS" ]; then
  echo -e "\n${GREEN}No snapshots found for subvolume: $SUBVOL_NAME${NC}"
  exit 0
fi

echo -e "\n${GREEN}Snapshots found: $SNAPSHOTS${NC}"

# Loop through each snapshot and check for clone statuses
for SNAP_NAME in $SNAPSHOTS; do
  echo -e "\n${GREEN}Checking snapshot info for snapshot: $SNAP_NAME${NC}"

  # Retrieve snapshot info, including pending clones
  SNAP_INFO=$(kubectl rook-ceph ceph fs subvolume snapshot info "$VOLUME_NAME" "$SUBVOL_NAME" "$SNAP_NAME" --group_name csi --format json)

  # Check if there are pending clones
  HAS_PENDING_CLONES=$(echo "$SNAP_INFO" | jq -r '.has_pending_clones')

  if [ "$HAS_PENDING_CLONES" == "yes" ]; then
    echo -e "\n${GREEN}Snapshot $SNAP_NAME has pending clones.${NC}"

    # Extract and display information about the pending clones
    PENDING_CLONES=$(echo "$SNAP_INFO" | jq -r '.pending_clones[] | .name')

    for CLONE_NAME in $PENDING_CLONES; do
      echo -e "${GREEN}Found pending clone: $CLONE_NAME${NC}\n"

      # Check the clone status
      kubectl rook-ceph ceph fs clone status "$VOLUME_NAME" "$CLONE_NAME" --group_name csi --format json | jq .
    done
  else
    echo -e "\n${GREEN}No pending clones for snapshot: $SNAP_NAME${NC}\n"
  fi
done