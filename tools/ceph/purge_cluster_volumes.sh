#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the current kubectl context
current_context=$(kubectl config current-context)
export current_context

# Prompt the user for confirmation
echo "You are currently using the kubectl context: $current_context"
read -p "Do you want to continue with this context? (y/n) " -n 1 -r
echo    # Move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting script."
    exit 1
fi

echo "Continuing with context: $current_context..."

# Variables
POOL=${1:-"k8s-rbd"}
NAMESPACE=${2:-"$current_context"}
SUBVOLUME_FS="k8s-cephfs"
RBD_COMMAND="ssh root@10.0.0.100 rbd"
CEPH_COMMAND="ssh root@10.0.0.100 ceph"

# Dry-run flag
DRY_RUN=false
if [[ "$3" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}Dry-run mode enabled. No images or subvolumes will be deleted.${NC}"
fi

# Gather all RBD images and Ceph subvolumes
gather_resources() {
    echo -e "${GREEN}Gathering resources from pool '${POOL}' and subvolumegroup '${NAMESPACE}'...${NC}"

    # Fetch RBD images
    RBD_IMAGES=$($RBD_COMMAND --pool "${POOL}" --namespace "${NAMESPACE}" ls 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to fetch RBD images. Ensure the RBD command is correct and the pool/namespace exists.${NC}"
        RBD_IMAGES=""
    fi

    # Fetch Ceph subvolumes
    CEPH_SUBVOLUMES=$($CEPH_COMMAND fs subvolume ls "${SUBVOLUME_FS}" --group_name="${NAMESPACE}" --format json 2>/dev/null | jq -r '.[].name')
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to fetch Ceph subvolumes. Ensure the Ceph command is correct and the filesystem/subvolumegroup exists.${NC}"
        CEPH_SUBVOLUMES=""
    fi

    # Combine resources
    echo -e "${GREEN}Resources to be deleted:${NC}"

    if [[ -n "$RBD_IMAGES" ]]; then
        echo -e "${YELLOW}RBD Images:${NC}"
        for IMAGE in $RBD_IMAGES; do
            echo -e "  * $IMAGE"
        done
    else
        echo -e "${RED}No RBD images found.${NC}"
    fi

    if [[ -n "$CEPH_SUBVOLUMES" ]]; then
        echo -e "${YELLOW}Ceph Subvolumes:${NC}"
        for SUBVOLUME in $CEPH_SUBVOLUMES; do
            echo -e "  * $SUBVOLUME"
        done
    else
        echo -e "${RED}No Ceph subvolumes found.${NC}"
    fi

    if [[ -z "$RBD_IMAGES" && -z "$CEPH_SUBVOLUMES" ]]; then
        echo -e "${RED}No resources found to delete.${NC}"
        exit 0
    fi

    # Confirm deletion
    echo -e "${YELLOW}The above resources will be deleted from namespace '${NAMESPACE}'.${NC}"
    read -p "Type 'yes' to confirm: " CONFIRMATION
    if [[ "$CONFIRMATION" != "yes" ]]; then
        echo -e "${RED}Confirmation not received. Exiting script.${NC}"
        exit 1
    fi
}

# Delete RBD images
delete_rbd_images() {
    echo -e "${GREEN}Deleting RBD images...${NC}"
    for IMAGE in $RBD_IMAGES; do
        if [[ -n "$IMAGE" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo -e "${YELLOW}[Dry-run] RBD Image to delete: $IMAGE${NC}"
            else
                echo -e "${GREEN}Deleting RBD Image: $IMAGE${NC}"
                $RBD_COMMAND --pool "${POOL}" --namespace "${NAMESPACE}" rm "$IMAGE"
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}Successfully deleted: $IMAGE${NC}"
                else
                    echo -e "${RED}Failed to delete: $IMAGE${NC}"
                fi
            fi
        fi
    done
}

# Delete Ceph subvolumes
delete_ceph_subvolumes() {
    echo -e "${GREEN}Deleting Ceph subvolumes...${NC}"
    for SUBVOLUME in $CEPH_SUBVOLUMES; do
        if [[ -n "$SUBVOLUME" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo -e "${YELLOW}[Dry-run] Subvolume to delete: $SUBVOLUME${NC}"
            else
                echo -e "${GREEN}Deleting Subvolume: $SUBVOLUME${NC}"
                $CEPH_COMMAND fs subvolume rm "${SUBVOLUME_FS}" --group_name="${NAMESPACE}" "$SUBVOLUME"
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}Successfully deleted: $SUBVOLUME${NC}"
                else
                    echo -e "${RED}Failed to delete: $SUBVOLUME${NC}"
                fi
            fi
        fi
    done
}

# Main workflow
gather_resources
delete_rbd_images
delete_ceph_subvolumes

echo -e "${GREEN}All resources have been processed.${NC}"