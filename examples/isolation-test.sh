#!/usr/bin/env bash
# isolation-test.sh - Simple script to test guard isolation
# 
# This script demonstrates isolation by creating a file in a specific location.
# When run with --guard, the file should appear inside the isolated environment,
# not on the host system (for docker) or in a different chroot namespace.

echo "Running isolation test..."
echo ""

# Create a marker file to prove we executed
TIMESTAMP=$(date +%s)
MARKER_FILE="/tmp/ursh-isolation-marker-${TIMESTAMP}.txt"

echo "Isolation test at $(date)" > "$MARKER_FILE"
echo "PID: $$" >> "$MARKER_FILE"
echo "User: $(whoami)" >> "$MARKER_FILE"

if [[ -f "$MARKER_FILE" ]]; then
    echo "✓ Created marker file: $MARKER_FILE"
    cat "$MARKER_FILE"
else
    echo "✗ Failed to create marker file"
    exit 1
fi