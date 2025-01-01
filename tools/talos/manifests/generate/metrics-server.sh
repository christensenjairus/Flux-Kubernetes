#!/bin/bash

# Ensure that a version number is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version> (leave the prepended 'v' off the version number)"
  exit 1
fi

set -e

VERSION=$1

# Get the directory of the script to ensure the output path is relative to the script's location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the output path for the manifest file
OUTPUT_FILE="${SCRIPT_DIR}/../raw/metrics-server-v${VERSION}.yaml"
rm -rf OUTPUT_FILE 2>/dev/null | true

# Get the manifest file for the specified version
wget -q https://github.com/kubernetes-sigs/metrics-server/releases/download/v${VERSION}/high-availability-1.21+.yaml -O "$OUTPUT_FILE"

yq e '.spec.template.spec.containers[].args += "--kubelet-insecure-tls=true"' -i "$OUTPUT_FILE"

# Notify the user of the output file location
echo "Metrics-server manifest generated for v${VERSION} at: $OUTPUT_FILE"