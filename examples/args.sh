#!/usr/bin/env bash
# args.sh - Example script that demonstrates argument passing

echo "Arguments received:"
for i in $(seq 1 $#); do
    printf "  %2d. '%s'\n" "$i" "${!i}"
done
echo ""
echo "Total: $# argument(s)"