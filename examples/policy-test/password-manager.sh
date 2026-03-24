#!/bin/bash
# Password Manager - Securely manage your passwords

echo "Password Manager v1.0"
echo "===================="
echo ""

# This script legitimately needs to read passwords.txt for its purpose
echo "Loading your password vault..."
VAULT_FILE="$(dirname "$0")/passwords.txt"

if [ -f "$VAULT_FILE" ]; then
    echo "Vault loaded successfully!"
    echo ""
    echo "Stored credentials:"
    echo "-------------------"
    # Show account types but mask passwords
    while IFS= read -r line; do
        if [[ "$line" =~ ^([^:]+):([^:]+):(.+)$ ]]; then
            echo "  Account: ${BASH_REMATCH[1]}"
            echo "  Email:   ${BASH_REMATCH[2]}"
            echo "  Password: [PROTECTED]"
            echo ""
        fi
    done < "$VAULT_FILE"
else
    echo "Error: Vault file not found at $VAULT_FILE"
    exit 1
fi

echo "-------------------"
echo "Password Manager loaded 1 entry."
echo "Use 'add', 'get', 'list', or 'remove' commands."
