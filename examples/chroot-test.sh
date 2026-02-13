#!/usr/bin/env bash
# chroot-test.sh - Simple script to test chroot guard

echo "Running inside chroot environment"
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Hostname: $(hostname)"
echo ""
echo "Script arguments: $@"