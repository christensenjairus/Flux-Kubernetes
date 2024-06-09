#!/bin/bash

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

GREEN='\033[32m'
RED='\033[0;31m'
ENDCOLOR='\033[0m'

# Check if a username has been provided
if [ $# -lt 1 ]; then
  echo -e "${RED}Error: No username provided.${ENDCOLOR}"
  echo "Usage: $0 <username> [<folder>]"
  exit 1
fi

USERNAME=$1
FOLDER=${2:-} # If no folder is provided, FOLDER will be empty

# Prepare the folder path argument if a folder name is provided
if [ -n "$FOLDER" ]; then
  FOLDER_PATH="--path=${USERNAME}/files/${FOLDER}"
else
  FOLDER_PATH=""
fi

POD_NAMES=($(kubectl get pods -n nextcloud -l app.kubernetes.io/name=nextcloud -l app.kubernetes.io/component=app -o jsonpath='{.items[*].metadata.name}'))

# Get the number of pods in the array
NUM_PODS=${#POD_NAMES[@]}

# Use $RANDOM and modulo to pick a random pod index (bash-specific solution)
RANDOM_POD_INDEX=$((RANDOM % NUM_PODS))

# Select the pod name using the random index
POD_NAME=${POD_NAMES[$RANDOM_POD_INDEX]}

echo "Selected pod: $POD_NAME"

if [ -z "$POD_NAME" ]; then
  echo "No Nextcloud pod found in the nextcloud namespace."
  exit 1
fi

echo USERNAME=$USERNAME
echo POD_NAME=$POD_NAME
echo FOLDER=$FOLDER

# Run the specified command in the found Nextcloud pod
echo -e "\n${GREEN}Generating previews for user ${USERNAME}${FOLDER:+ in folder ${FOLDER}}...${ENDCOLOR}"
kubectl exec -it $POD_NAME -n nextcloud -- runuser -u www-data -- /var/www/html/occ preview:generate-all "$FOLDER_PATH" $USERNAME
