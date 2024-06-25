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
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: No username provided.${ENDCOLOR}"
  echo "Usage: $0 <username>"
  exit 1
fi

USERNAME=$1

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

# Run the specified command in the found Nextcloud pod
echo -e "\n${GREEN}Temporarily disabling file locking...${ENDCOLOR}"
kubectl exec -it $POD_NAME -n nextcloud -- runuser -u www-data -- /var/www/html/occ config:system:set filelocking.enabled --value=false

# Run the specified command in the found Nextcloud pod
echo -e "\n${GREEN}Scanning files for user ${USERNAME}...${ENDCOLOR}"
kubectl exec -it $POD_NAME -n nextcloud -- runuser -u www-data -- /var/www/html/occ files:scan "$USERNAME"

# Run the specified command in the found Nextcloud pod
echo -e "\n${GREEN}Re enabling file locking...${ENDCOLOR}"
kubectl exec -it $POD_NAME -n nextcloud -- runuser -u www-data -- /var/www/html/occ config:system:set filelocking.enabled --value=true
