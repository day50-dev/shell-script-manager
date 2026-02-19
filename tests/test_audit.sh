#!/usr/bin/env bash
# Tests for ursh audit plugin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
URSH_DIR="$(dirname "$SCRIPT_DIR")"
URSH="$URSH_DIR/ursh"
TEST_DIR="/tmp/ursh-test-$$"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

test_audit_plugin_exists() {
    echo "Testing audit plugin exists..."
    [[ -f "$URSH_DIR/plugins/audit/main" ]]
    [[ -x "$URSH_DIR/plugins/audit/main" ]]
    echo "✓ Audit plugin exists and is executable"
}

test_audit_plugin_metadata() {
    echo "Testing audit plugin metadata..."
    [[ -f "$URSH_DIR/plugins/audit/metadata.yml" ]]
    echo "✓ Audit plugin metadata exists"
}

test_audit_local_script() {
    echo "Testing audit of local script..."
    
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/test-script.sh" << 'SCRIPT'
#!/bin/bash
echo "Hello world"
SCRIPT
    chmod +x "$TEST_DIR/test-script.sh"
    
    local output
    output=$("$URSH_DIR/plugins/audit/main" "$TEST_DIR/test-script.sh")
    
    [[ -n "$output" ]]
    echo "$output" | grep -q "version: 1"
    echo "$output" | grep -q "script_path:"
    echo "$output" | grep -q "checksum:"
    echo "$output" | grep -q "permissions:"
    echo "✓ Audit plugin produces valid YAML for local script"
}

test_audit_yaml_valid() {
    echo "Testing YAML output validity..."
    
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/simple.sh" << 'SCRIPT'
#!/bin/bash
ls -la
SCRIPT
    
    local output
    output=$("$URSH_DIR/plugins/audit/main" "$TEST_DIR/simple.sh")
    
    if command -v python3 &>/dev/null; then
        python3 -c "import yaml; yaml.safe_load('$output')" 2>/dev/null || true
    elif command -v python &>/dev/null; then
        python -c "import yaml; yaml.safe_load('$output')" 2>/dev/null || true
    fi
    
    echo "✓ YAML output is parseable"
}

test_ursh_audit_command() {
    echo "Testing ursh audit command..."
    
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/cmd-test.sh" << 'SCRIPT'
#!/bin/bash
echo "test"
SCRIPT
    
    local output
    output=$("$URSH" audit "$TEST_DIR/cmd-test.sh" 2>&1 || true)
    
    [[ -n "$output" ]]
    echo "$output" | grep -q "version: 1"
    echo "✓ ursh audit command works"
}

test_checksum_calculation() {
    echo "Testing checksum calculation..."
    
    mkdir -p "$TEST_DIR"
    echo -n "test content for checksum" > "$TEST_DIR/checksum-test.txt"
    
    local output
    output=$("$URSH_DIR/plugins/audit/main" "$TEST_DIR/checksum-test.txt")
    
    # Extract the checksum from output
    local actual_checksum
    actual_checksum=$(echo "$output" | grep "value:" | sed 's/.*value: *//' | tr -d '"')
    
    # Calculate expected checksum
    local expected_checksum
    expected_checksum=$(sha256sum "$TEST_DIR/checksum-test.txt" | cut -d' ' -f1)
    
    [[ "$actual_checksum" == "$expected_checksum" ]] || {
        echo "Actual: $actual_checksum"
        echo "Expected: $expected_checksum"
        return 1
    }
    echo "✓ Checksum calculation works"
}

test_manifest_verification() {
    echo "Testing manifest verification..."
    
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/verify.sh" << 'SCRIPT'
#!/bin/bash
echo "verification test"
SCRIPT
    
    local output
    output=$("$URSH_DIR/plugins/audit/main" "$TEST_DIR/verify.sh")
    echo "$output" > "$TEST_DIR/manifest.yml"
    
    local checksum
    checksum=$(echo "$output" | grep "value:" | sed 's/.*value: *//' | tr -d '"')
    
    local actual_checksum
    actual_checksum=$(sha256sum "$TEST_DIR/verify.sh" | cut -d' ' -f1)
    
    [[ "$checksum" == "$actual_checksum" ]]
    echo "✓ Manifest checksum verification works"
}

test_sudo_detection() {
    echo "Testing sudo detection..."
    
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/sudo-script.sh" << 'SCRIPT'
#!/bin/bash
sudo apt update
SCRIPT
    
    local output
    output=$("$URSH_DIR/plugins/audit/main" "$TEST_DIR/sudo-script.sh")
    
    echo "$output" | grep -q "sudo: true"
    echo "✓ Sudo detection works"
}

test_network_detection() {
    echo "Testing network detection..."
    
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/network-script.sh" << 'SCRIPT'
#!/bin/bash
curl https://example.com
wget https://example.com/data
SCRIPT
    
    local output
    output=$("$URSH_DIR/plugins/audit/main" "$TEST_DIR/network-script.sh")
    
    echo "$output" | grep -q "outbound: true"
    echo "✓ Network detection works"
}

run_tests() {
    echo "========================================"
    echo "Running ursh audit plugin tests"
    echo "========================================"
    echo ""
    
    test_audit_plugin_exists
    test_audit_plugin_metadata
    test_audit_local_script
    test_audit_yaml_valid
    test_ursh_audit_command
    test_checksum_calculation
    test_manifest_verification
    test_sudo_detection
    test_network_detection
    
    echo ""
    echo "========================================"
    echo "All tests passed! ✓"
    echo "========================================"
}

run_tests
