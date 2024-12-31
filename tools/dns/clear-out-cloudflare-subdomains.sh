#!/bin/bash

# Get the current kubectl context
export current_context=$(kubectl config current-context)

# Prompt the user for confirmation
echo "You are currently using the kubectl context: $current_context"
read -p "Do you want to continue with this context? (y/n) " -n 1 -r
echo    # (optional) move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting script."
    exit 1
fi

echo "Continuing with context $current_context..."

# Define the suffix to search for
SUFFIX="-${current_context}.christensencloud.us"

# Find all subdomains ending with the specified suffix
echo "Fetching subdomains ending with '${SUFFIX}'..."
subdomains=$(cfcli ls -f json | jq -r --arg suffix "$SUFFIX" '.[] | select(.name | endswith($suffix)) | .name')

# Check if any subdomains were found
if [ -z "$subdomains" ]; then
  echo "No subdomains found with the suffix '${SUFFIX}'. Exiting."
  exit 0
fi

# Display the subdomains to be deleted
echo "The following subdomains will be deleted:"
echo "$subdomains"

# Confirm deletion
read -p "Are you sure you want to delete these subdomains? Type 'yes' to confirm: " confirmation
if [[ "$confirmation" != "yes" ]]; then
  echo "Deletion canceled. Exiting."
  exit 0
fi

# Delete each subdomain
echo "Deleting subdomains..."
for subdomain in $subdomains; do
  echo "Deleting subdomain: $subdomain"
  cfcli rm "$subdomain"
  if [ $? -eq 0 ]; then
    echo "Successfully deleted: $subdomain"
  else
    echo "Failed to delete: $subdomain"
  fi
done

echo "All specified subdomains have been processed."