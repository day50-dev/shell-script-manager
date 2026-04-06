#!/bin/bash
# Example audited script - removes unused EBS volumes older than 30 days

set -euo pipefail

echo "Starting EBS cleanup..."

if [[ -z "${AWS_REGION:-}" ]]; then
    echo "AWS_REGION is required" >&2
    exit 1
fi

# List and filter old volumes
volumes=$(aws ec2 describe-volumes --region "$AWS_REGION" --filters "Name=status,Values=available" | jq -r '.Volumes[].VolumeId')

for volume in $volumes; do
    creation_date=$(aws ec2 describe-volumes --volume-ids "$volume" --region "$AWS_REGION" --query 'Volumes[0].CreateTime' --output text)
    age_days=$(( (($(date +%s) - $(date -d "$creation_date" +%s)) / 86400) ))
    
    if [[ $age_days -gt 30 ]]; then
        echo "Deleting volume $volume (age: ${age_days} days)"
        aws ec2 delete-volume --volume-id "$volume" --region "$AWS_REGION"
    fi
done

echo "Cleanup complete"
