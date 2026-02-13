#!/usr/bin/env bash
# docker-test.sh - Simple script to test docker guard

echo "Running inside Docker container"
echo "Image: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Hostname: $(hostname)"
echo ""
echo "Script arguments: $@"