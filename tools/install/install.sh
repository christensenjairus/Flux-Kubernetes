#!/bin/bash

# Define colors for feedback
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

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

# Get the directory of this script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Execute subscripts using the absolute path
"$SCRIPT_DIR/subscripts/unset-default-storageclass.sh"
"$SCRIPT_DIR/subscripts/onepassword-connect.sh"
"$SCRIPT_DIR/subscripts/flux.sh"
