#!/bin/bash

# Variables
STORAGECLASS_NAME="local-path"
ANNOTATION_KEY="storageclass.kubernetes.io/is-default-class"

# Check if the StorageClass exists
echo -e "${GREEN}Checking if StorageClass '${STORAGECLASS_NAME}' exists...${NC}"
kubectl get storageclass "${STORAGECLASS_NAME}" &>/dev/null
if [[ $? -ne 0 ]]; then
    echo -e "${RED}StorageClass '${STORAGECLASS_NAME}' not found. Exiting.${NC}"
    exit 1
fi

# Remove the annotation
echo -e "${GREEN}Removing '${ANNOTATION_KEY}' annotation from StorageClass '${STORAGECLASS_NAME}'...${NC}"
kubectl annotate storageclass "${STORAGECLASS_NAME}" "${ANNOTATION_KEY}-" --overwrite &>/dev/null
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Successfully removed '${ANNOTATION_KEY}' annotation from '${STORAGECLASS_NAME}'.${NC}"
else
    echo -e "${RED}Failed to remove the annotation. Please check your permissions and try again.${NC}"
    exit 1
fi

# Verify the annotation has been removed
echo -e "${GREEN}Verifying the annotation removal...${NC}"
ANNOTATIONS=$(kubectl get storageclass "${STORAGECLASS_NAME}" -o jsonpath="{.metadata.annotations}")
if [[ "$ANNOTATIONS" == *"${ANNOTATION_KEY}"* ]]; then
    echo -e "${RED}Annotation '${ANNOTATION_KEY}' still exists on '${STORAGECLASS_NAME}'. Please check for errors.${NC}"
    exit 1
else
    echo -e "${GREEN}Annotation '${ANNOTATION_KEY}' successfully removed from '${STORAGECLASS_NAME}'.${NC}"
fi