#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

VERBOSE=false
DEBUG=false

# Parse arguments
for arg in "$@"
do
    if [ "$arg" == "--verbose" ]; then
        VERBOSE=true
    fi
    if [ "$arg" == "--debug" ]; then
        DEBUG=true
    fi
done

# Function to print verbose messages with [VERBOSE] prefix
verbose_echo() {
    if [ "$VERBOSE" == true ]; then
        echo -e "${GREEN}[VERBOSE]${NC} $1"
    fi
}

verbose_echo_good() {
    if [ "$VERBOSE" == true ]; then
        echo -e "${GREEN}[VERBOSE] $1${NC}"
    fi
}

verbose_echo_bad() {
    if [ "$VERBOSE" == true ]; then
        echo -e "${RED}[VERBOSE] $1${NC}"
    fi
}

# Function to print debug messages with [DEBUG] prefix
debug_echo() {
    if [ "$DEBUG" == true ]; then
        echo -e "${GREEN}[DEBUG]${NC} $1"
    fi
}

# Function to continuously refresh the screen
while true; do
  # Clear the screen
  clear

  # Print table header with adjusted column width
  printf "\n%-41s | %-12s | %-17s\n" "Namespace/PVC" "Snapshots" "Pending Clones"
  printf "%-41s | %-12s | %-17s\n" "-----------------------------------------" "------------" "-----------------"

  # Get all PVCs in the cluster where the storage class name starts with 'ceph-filesystem'
  PVC_LIST=$(kubectl get pvc --all-namespaces -o json | jq -r '.items[] | select(.spec.storageClassName | startswith("ceph-filesystem")) | select(.metadata.namespace != "velero") | [.metadata.namespace, .metadata.name, .spec.storageClassName] | @csv' | tr -d '"')

  if [ -z "$PVC_LIST" ]; then
    verbose_echo_bad "No PVCs found with storage class starting with 'ceph-filesystem'"
    exit 0
  fi

  # Iterate over each PVC
  while IFS=',' read -r NAMESPACE PVC_NAME STORAGE_CLASS; do
    verbose_echo "Namespace: $NAMESPACE"
    verbose_echo "PVC Name: $PVC_NAME"
    verbose_echo "StorageClass: $STORAGE_CLASS"

    # Find the Persistent Volume associated with the PVC
    PV_NAME=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" --output=jsonpath='{.spec.volumeName}')
    if [ -z "$PV_NAME" ]; then
      verbose_echo_bad "Error: Could not find PV associated with PVC $PVC_NAME in namespace $NAMESPACE"
      continue
    fi

    verbose_echo "Found PV name: $PV_NAME"

    # Extract the subvolume name from the PV spec
    SUBVOL_NAME=$(kubectl get pv "$PV_NAME" --output=jsonpath='{.spec.csi.volumeAttributes.subvolumeName}')
    if [ -z "$SUBVOL_NAME" ]; then
      verbose_echo_bad "Error: Could not retrieve subvolume name from PV $PV_NAME"
      continue
    fi

    verbose_echo "Found subvolume name: $SUBVOL_NAME"

    # Get the list of snapshots for the subvolume
    verbose_echo "Retrieving snapshots for subvolume: $SUBVOL_NAME"
    SNAPSHOTS=$(kubectl rook-ceph ceph fs subvolume snapshot ls "$STORAGE_CLASS" "$SUBVOL_NAME" --group_name csi --format json 2>&1 | grep -v "Info:")

    # Print the raw output of the Ceph snapshot command in debug mode
    debug_echo "Ceph snapshot list output: $SNAPSHOTS"

    # Parse the JSON part of the output
    SNAPSHOTS=$(echo "$SNAPSHOTS" | jq -r '.[] | .name')

    # Count the number of snapshots and trim whitespace
    SNAPSHOT_COUNT=$(echo "$SNAPSHOTS" | grep -v '^$' | wc -l | xargs)

    if [ -z "$SNAPSHOTS" ] || [ "$SNAPSHOT_COUNT" -eq 0 ]; then
      # Print PVCs with no snapshots in green
      printf "${GREEN}%-41s | %-12s | %-17s${NC}\n" "$NAMESPACE/$PVC_NAME" "No Snapshots" "No Pending Clones"
      continue
    fi

    verbose_echo "Snapshots found: $SNAPSHOTS"

    # Initialize counter for pending snapshots
    PENDING_SNAPSHOTS=0

    # Loop through each snapshot and check for pending clone statuses
    for SNAP_NAME in $SNAPSHOTS; do
      verbose_echo "Checking snapshot info for snapshot: $SNAP_NAME"

      # Retrieve snapshot info, including pending clones
      SNAP_INFO=$(kubectl rook-ceph ceph fs subvolume snapshot info "$STORAGE_CLASS" "$SUBVOL_NAME" "$SNAP_NAME" --group_name csi --format json 2>&1 | grep -v "Info:")

      # Print the raw output of the Ceph snapshot info command in debug mode
      debug_echo "Ceph snapshot info output for $SNAP_NAME: $SNAP_INFO"

      # Check if there are pending clones
      HAS_PENDING_CLONES=$(echo "$SNAP_INFO" | jq -r '.has_pending_clones')

      if [ "$HAS_PENDING_CLONES" == "yes" ]; then
        PENDING_SNAPSHOTS=$((PENDING_SNAPSHOTS + 1))
        verbose_echo "Snapshot $SNAP_NAME has pending clones."
      else
        verbose_echo "No pending clones for snapshot: $SNAP_NAME"
      fi
    done

    # After counting pending snapshots, print formatted table row with number of snapshots
    if [ "$PENDING_SNAPSHOTS" -gt 0 ]; then
      printf "${RED}%-41s | %-12s | %-17s${NC}\n" "$NAMESPACE/$PVC_NAME" "$SNAPSHOT_COUNT Snapshot(s)" "$PENDING_SNAPSHOTS Pending Clone(s)"
    else
      printf "${GREEN}%-41s | %-12s | %-17s${NC}\n" "$NAMESPACE/$PVC_NAME" "$SNAPSHOT_COUNT Snapshot(s)" "No Pending Clones"
    fi

  done <<< "$PVC_LIST"

  # Wait 30 seconds before the next update (change this value if needed)
  # Countdown before the next refresh
  countdown=30  # Set the countdown duration (in seconds)

  echo -n "Refreshing in $countdown seconds..."

  while [ $countdown -gt 0 ]; do
    # Move the cursor to the beginning of the line and clear the line
    echo -ne "\rRefreshing in $countdown seconds... "

    # Sleep for 1 second
    sleep 1

    # Decrease the countdown
    countdown=$((countdown - 1))
  done

  # Move to the next line after the countdown finishes
  echo ""

done