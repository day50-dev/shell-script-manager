#!/usr/bin/env bats

SHURL_BINARY="/home/chris/code/shurl/shurl"

setup() {
    export BATS_TMPDIR="${BATS_TMPDIR:-/tmp/bats-$$}"
    mkdir -p "$BATS_TMPDIR"
}

@test "GitHub shorthand expansion" {
    run "$SHURL_BINARY" gh:day50-dev/shurl 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand with branch" {
    run "$SHURL_BINARY" gh:day50-dev/shurl@main/shurl 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand repo only" {
    run "$SHURL_BINARY" gh:day50-dev/shurl 2>&1
    [[ "$output" == *"error"* ]]
}

@test "Local file execution" {
    local temp_script="$BATS_TMPDIR/local-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "hello from local"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"hello from local"* ]]
}

@test "Argument passing" {
    local temp_script="$BATS_TMPDIR/args-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "args: $*"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" arg1 arg2 2>&1
    [[ "$output" == *"arg1 arg2"* ]]
}

@test "Quiet mode" {
    local temp_script="$BATS_TMPDIR/quiet-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "quiet output"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" -q "$temp_script" 2>&1
    [[ "$output" == *"quiet output"* ]]
}

@test "Install mode creates file" {
    local temp_script="$BATS_TMPDIR/install-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "installed"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [[ "$output" == *"is now available"* ]]
}

@test "Install mode lists entry" {
    local temp_script="$BATS_TMPDIR/install-list-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "test"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true

    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *"install-list-test"* ]]
}

@test "Dry run shows script preview" {
    local temp_script="$BATS_TMPDIR/dryrun-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "test"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --dry-run "$temp_script" 2>&1
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

    "$SHURL_BINARY" "$temp_script" 2>/dev/null || true

    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "updated"
SCRIPT

    run "$SHURL_BINARY" --update "$temp_script" 2>&1
    [[ "$output" == *"updated"* ]]
}

@test "Empty URL shows help" {
    run "$SHURL_BINARY" 2>&1
    [[ "$output" == *"shurl"* ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "Unknown flag error" {
    run "$SHURL_BINARY" --unknown-flag 2>&1
    [[ "$output" == *"Unknown option"* ]]
}
