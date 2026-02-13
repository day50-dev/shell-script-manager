#!/usr/bin/env bash
# guard-test.sh - Example script to test guard functionality

echo "Hello from inside the container!"
echo "Current date: $(date)"
echo "Current user: $(whoami)"
echo "Hostname: $(hostname)"
echo ""
echo "This script was run through the guard wrapper."