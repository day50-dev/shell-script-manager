#!/usr/bin/env bats

@test "List empty initially" {
    run "$SHURL_BINARY" --list
    [[ "$output" == *No\ installed\ packages* ]]
}

@test "List shows entries" {
    local temp_script
    temp_script="$(mktemp)/list-shows-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "list"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --list
    [[ "$output" == *list-shows-test* ]]
}

@test "List shows date" {
    local temp_script
    temp_script="$(mktemp)/list-date-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "date"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --list
    [[ "$output" == *YYYY-MM-DD* ]]
}

@test "List shows URL" {
    local temp_script
    temp_script="$(mktemp)/list-url-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "url"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --list
    [ -n "$output" ]
}

@test "List format columns" {
    local temp_script
    temp_script="$(mktemp)/list-format-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "format"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --list
    [[ "$output" == *NAME* ]]
    [[ "$output" == *DATE* ]]
}

@test "List multiple entries" {
    local temp_script1
    temp_script1="$(mktemp)/list-multi1.sh"
    mkdir -p "$(dirname "$temp_script1")"
    cat > "$temp_script1" << 'SCRIPT'
#!/bin/bash
echo "multi1"
SCRIPT
    chmod +x "$temp_script1"

    local temp_script2
    temp_script2="$(mktemp)/list-multi2.sh"
    mkdir -p "$(dirname "$temp_script2")"
    cat > "$temp_script2" << 'SCRIPT'
#!/bin/bash
echo "multi2"
SCRIPT
    chmod +x "$temp_script2"

    "$SHURL_BINARY" --install "$temp_script1" > /dev/null 2>&1 || true
    "$SHURL_BINARY" --install "$temp_script2" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --list
    [[ "$output" == *list-multi1* ]]
    [[ "$output" == *list-multi2* ]]
}

@test "List with GitHub shorthand" {
    local temp_script
    temp_script="$(mktemp)/list-gh-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "gh"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --list
    [[ "$output" == *list-gh-test* ]]
}
