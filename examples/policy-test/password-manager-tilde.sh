#!/bin/bash
# Password Manager - Securely manage your passwords (with tilde path access)

echo "Password Manager v1.0"
echo "===================="
echo ""

# Access home directory path
echo "Loading your password vault from home directory..."
cat ~/passwords.txt 2>/dev/null || echo "No vault found in home directory"

echo ""
echo "Password Manager ready."
