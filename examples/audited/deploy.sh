#!/bin/bash
# Simple deployment script example

set -euo pipefail

echo "Deploying application..."

if [[ -z "${DEPLOY_ENV:-}" ]]; then
    echo "DEPLOY_ENV is required" >&2
    exit 1
fi

echo "Deploying to: $DEPLOY_ENV"
echo "Current directory: $(pwd)"

# Deploy logic here
echo "Deployment complete"
