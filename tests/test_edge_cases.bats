#!/usr/bin/env bats

SHURL_BINARY="/home/chris/code/shurl/shurl"

@test "URL with query parameters" {
    run "$SHURL_BINARY" "https://example.com/script.sh?foo=bar" 2>&1
    [[ "$output" == *"error"* ]]
}

@test "URL with spaces (quoted)" {
    local temp_script="$BATS_TMPDIR/spaced script.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "spaced"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"spaced"* ]]
}

@test "Script with special characters in output" {
    local temp_script="$BATS_TMPDIR/special.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "Special: \$HOME & <test> | 'quotes'"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"Special:"* ]]
}

@test "Script with newlines in output" {
    local temp_script="$BATS_TMPDIR/newlines.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
printf "line1\nline2\nline3\n"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"line1"* ]]
    [[ "$output" == *"line2"* ]]
    [[ "$output" == *"line3"* ]]
}

@test "Script with very long output" {
    local temp_script="$BATS_TMPDIR/long.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
for i in {1..100}; do echo "line $i"; done
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"line 1"* ]]
    [[ "$output" == *"line 100"* ]]
}

@test "Empty script" {
    local temp_script="$BATS_TMPDIR/empty.sh"
    touch "$temp_script"
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1 || true
    [ "$status" -ne 0 ]
}

@test "Script with exit code 1" {
    local temp_script="$BATS_TMPDIR/exit1.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
exit 1
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [ "$status" -eq 1 ]
}

@test "Script with exit code 42" {
    local temp_script="$BATS_TMPDIR/exit42.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
exit 42
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [ "$status" -eq 42 ]
}

@test "Script that reads environment variable" {
    local temp_script="$BATS_TMPDIR/env.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "value: $TEST_VAR"
SCRIPT
    chmod +x "$temp_script"

    run bash -c "TEST_VAR=hello $SHURL_BINARY $temp_script" 2>&1
    [[ "$output" == *"value: hello"* ]]
}

@test "Script with no trailing newline" {
    local temp_script="$BATS_TMPDIR/no-newline.sh"
    printf '#!/bin/bash\necho "no newline"' > "$temp_script"
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"no newline"* ]]
}

@test "Script with only shebang" {
    local temp_script="$BATS_TMPDIR/shebang-only.sh"
    printf '#!/bin/bash\n' > "$temp_script"
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [ "$status" -eq 0 ]
}

@test "Script with binary content" {
    local temp_script="$BATS_TMPDIR/binary.sh"
    printf '#!/bin/bash\necho "binary"' > "$temp_script"
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *"binary"* ]]
}
