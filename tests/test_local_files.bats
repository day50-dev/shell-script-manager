#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

@test "Local file execution" {
    local temp_script="$BATS_TMPDIR/local-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "local output"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"local output"* ]]
}

@test "Local file with arguments" {
    local temp_script="$BATS_TMPDIR/local-args.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "args: $*"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" "$temp_script" arg1 arg2 2>&1
    [[ "$output" == *"arg1 arg2"* ]]
}

@test "Local file bypasses cache" {
    local temp_script="$BATS_TMPDIR/nocache.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "no cache"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" --update "$temp_script" 2>&1
    [[ "$output" == *"no cache"* ]]
}

@test "Local file shows in dry-run" {
    local temp_script="$BATS_TMPDIR/dry-local.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "dry"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" --dry-run "$temp_script" 2>&1
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"local file"* ]]
}

@test "Non-existent local file errors" {
    run "$URSH_BINARY" /nonexistent/file.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "Local file with shebang" {
    local temp_script="$BATS_TMPDIR/shebang-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "shebang"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"shebang"* ]]
}

@test "Local file without shebang warns but runs" {
    local temp_script="$BATS_TMPDIR/no-shebang.sh"
    cat > "$temp_script" << 'SCRIPT'
echo "no shebang"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" -q "$temp_script" 2>&1
    [[ "$output" == *"no shebang"* ]]
}

@test "Local file with quiet mode" {
    local temp_script="$BATS_TMPDIR/quiet-local.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "quiet"
SCRIPT
    chmod +x "$temp_script"

    run "$URSH_BINARY" -q "$temp_script" 2>&1
    [[ "$output" == *"quiet"* ]]
}
