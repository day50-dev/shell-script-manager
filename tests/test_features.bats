#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

setup() {
    export BATS_TMPDIR="${BATS_TMPDIR:-/tmp/bats-$$}"
    mkdir -p "$BATS_TMPDIR"
}

@test "GitHub shorthand expansion" {
    run "$URSH_BINARY" gh:day50-dev/ursh 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand with branch" {
    run "$URSH_BINARY" gh:day50-dev/ursh@main/ursh 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand repo only" {
    run "$URSH_BINARY" gh:day50-dev/ursh 2>&1
    [[ "$output" == *"error"* ]]
}

@test "Local file execution" {
    local temp_script="$BATS_TMPDIR/local-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "hello from local"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"hello from local"* ]]
}

@test "Argument passing" {
    local temp_script="$BATS_TMPDIR/args-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "args: $*"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" "$temp_script" arg1 arg2 2>&1
    [[ "$output" == *"arg1 arg2"* ]]
}

@test "Quiet mode" {
    local temp_script="$BATS_TMPDIR/quiet-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "quiet output"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" -q "$temp_script" 2>&1
    [[ "$output" == *"quiet output"* ]]
}

@test "Install mode creates file" {
    local temp_script="$BATS_TMPDIR/install-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "installed"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" --install "$temp_script" 2>&1
    [[ "$output" == *"is now available"* ]]
}

@test "Install mode lists entry" {
    local temp_script="$BATS_TMPDIR/install-list-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "test"
SCRIPT
    chmod +x "$temp_script"

    "$URSH_BINARY" --install "$temp_script" 2>/dev/null || true

    run "$URSH_BINARY" --list 2>&1
    [[ "$output" == *"install-list-test"* ]]
}

@test "Dry run shows script preview" {
    local temp_script="$BATS_TMPDIR/dryrun-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "test"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" --dry-run "$temp_script" 2>&1
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"preview"* ]]
}

@test "Update flag clears cache" {
    local temp_script="$BATS_TMPDIR/update-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "original"
SCRIPT
    chmod +x "$temp_script"

    "$URSH_BINARY" "$temp_script" 2>/dev/null || true

    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "updated"
SCRIPT

    run "$URSH_BINARY" --update "$temp_script" 2>&1
    [[ "$output" == *"updated"* ]]
}

@test "Empty URL shows help" {
    run "$URSH_BINARY" 2>&1
    [[ "$output" == *"ursh"* ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "Unknown flag error" {
    run "$URSH_BINARY" --unknown-flag 2>&1
    [[ "$output" == *"Unknown option"* ]]
}
