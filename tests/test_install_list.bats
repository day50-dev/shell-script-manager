#!/usr/bin/env bats

SHURL_BINARY="/home/chris/code/shurl/shurl"

setup() {
    export HOME="$BATS_TMPDIR/home"
    mkdir -p "$HOME/.local/bin"
}

teardown() {
    rm -rf "$BATS_TMPDIR/home" 2>/dev/null || true
}

@test "List shows no packages when empty" {
    rm -f "$HOME/.cache/shurl/install-list.txt" 2>/dev/null || true
    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *"No installed packages"* ]]
}

@test "List shows installed packages" {
    local temp_script="$BATS_TMPDIR/list-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "test"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true

    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *"list-test"* ]]
}

@test "List shows date and URL" {
    local temp_script="$BATS_TMPDIR/date-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "date"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true

    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *date-test* ]]
}

@test "List format is correct" {
    local temp_script="$BATS_TMPDIR/format-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "format"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true

    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *"NAME"* ]]
    [[ "$output" == *"DATE"* ]]
    [[ "$output" == *"URL"* ]]
}

@test "List with multiple packages" {
    local temp_script1="$BATS_TMPDIR/multi1.sh"
    local temp_script2="$BATS_TMPDIR/multi2.sh"
    cat > "$temp_script1" << 'SCRIPT'
#!/bin/bash
echo "1"
SCRIPT
    cat > "$temp_script2" << 'SCRIPT'
#!/bin/bash
echo "2"
SCRIPT
    chmod +x "$temp_script1" "$temp_script2"

    "$SHURL_BINARY" --install "$temp_script1" 2>/dev/null || true
    "$SHURL_BINARY" --install "$temp_script2" 2>/dev/null || true

    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *"multi1"* ]]
    [[ "$output" == *"multi2"* ]]
}

@test "List shows full path when installed" {
    local temp_script="$BATS_TMPDIR/fullpath-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "full"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true

    run "$SHURL_BINARY" --list 2>&1
    [[ "$output" == *"fullpath-test"* ]]
}
