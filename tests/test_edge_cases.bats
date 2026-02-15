#!/usr/bin/env bats

@test "Guard docker unavailable" {
    run "$SHURL_BINARY" --guard docker https://example.com/script.sh 2>&1
    [[ "$output" == *docker* ]]
}

@test "Guard chroot unavailable" {
    run "$SHURL_BINARY" --guard chroot https://example.com/script.sh 2>&1
    [[ "$output" == *chroot* ]]
}

@test "Guard invalid type" {
    run "$SHURL_BINARY" --guard invalid https://example.com/script.sh 2>&1
    [[ "$output" == *Unknown\ guard\ type* ]]
}

@test "Guard type required" {
    run "$SHURL_BINARY" --guard 2>&1
    [[ "$output" == *requires\ a\ type* ]]
}

@test "Update by package name" {
    local temp_script
    temp_script="$(mktemp)/update-pkg-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "pkg"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    run "$SHURL_BINARY" --update update-pkg-test 2>&1
    [[ "$output" == *error* ]]
}

@test "No shebang warning" {
    local temp_script
    temp_script="$(mktemp)/no-shebang-test"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
echo "no shebang"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *Warning* ]]
}

@test "Empty script error" {
    local temp_script
    temp_script="$(mktemp)/empty-script-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    touch "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *error* ]]
}

@test "Missing file error" {
    run "$SHURL_BINARY" /nonexistent/file.sh 2>&1
    [[ "$output" == *error* ]]
}

@test "Invalid GitHub format" {
    run "$SHURL_BINARY" gh:invalid 2>&1
    [[ "$output" == *Invalid\ GitHub\ shorthand* ]]
}

@test "GitHub with query params" {
    run "$SHURL_BINARY" https://raw.githubusercontent.com/user/repo/main/file.sh?query=1 2>&1
    [[ "$output" == *error* ]]
}

@test "Install with special chars in name" {
    local temp_script
    temp_script="$(mktemp)/special-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "special"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [[ "$output" == *is\ now\ available* ]]
}

@test "List shows empty state" {
    run "$SHURL_BINARY" --list
    [[ "$output" == *No\ installed\ packages* ]]
}

@test "Version output format" {
    run "$SHURL_BINARY" --version
    [[ "$output" == *shurl\ v* ]]
}

@test "Help shows all options" {
    run "$SHURL_BINARY" --help
    [[ "$output" == *\ --dry-run\ * ]]
    [[ "$output" == *\ --update\ * ]]
    [[ "$output" == *\ --install\ * ]]
    [[ "$output" == *\ --list\ * ]]
}
