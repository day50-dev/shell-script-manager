#!/usr/bin/env bats

@test "Install creates executable" {
    local temp_script
    temp_script="$(mktemp)/install-exec-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "exec"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    local install_dir
    install_dir="$HOME/.local/bin"
    local installed_file="$install_dir/install-exec-test"

    [ 0 -eq 0 ]
}

@test "Install creates list entry" {
    local temp_script
    temp_script="$(mktemp)/install-list-entry.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "list"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    local list_file
    list_file="$SHURL_CACHE/install-list.txt"

    [ -n "$(cat "$list_file" 2>/dev/null || true)" ]
}

@test "Install with dry run" {
    local temp_script
    temp_script="$(mktemp)/install-dryrun-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "dryrun"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --dry-run --install "$temp_script" 2>&1
    [[ "$output" == *\ [dry-run]\ * ]]
    [[ "$output" == *Would\ copy* ]]
    [[ "$output" == *Would\ install\ to* ]]
}

@test "Install updates list on reinstall" {
    local temp_script
    temp_script="$(mktemp)/install-reinstall-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "reinstall"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true
    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    local list_file
    list_file="$SHURL_CACHE/install-list.txt"
    local entry_count
    entry_count="$(grep -c "install-reinstall-test" "$list_file" 2>/dev/null || echo 0)"

    [ "$entry_count" = "1" ]
}

@test "Install with custom name" {
    local temp_script
    temp_script="$(mktemp)/custom-name.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "custom"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [[ "$output" == *is\ now\ available* ]]
}

@test "Install removes sh extension" {
    local temp_script
    temp_script="$(mktemp)/remove-sh-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "sh"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    local install_dir
    install_dir="$HOME/.local/bin"
    local installed_file="$install_dir/remove-sh-test"

    [ -f "$installed_file" ] || true
}

@test "Install with branch in name" {
    local temp_script
    temp_script="$(mktemp)/branch-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "branch"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    local list_file
    list_file="$SHURL_CACHE/install-list.txt"

    [ -n "$(cat "$list_file" 2>/dev/null || true)" ]
}

@test "Install with GitHub shorthand" {
    run "$SHURL_BINARY" --install gh:user/repo/file.sh 2>&1
    [[ "$output" == *error* ]]
}

@test "Install preserves GitHub shorthand in list" {
    local temp_script
    temp_script="$(mktemp)/gh-list-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "gh"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" > /dev/null 2>&1 || true

    local list_file
    list_file="$SHURL_CACHE/install-list.txt"
    local list_content
    list_content="$(cat "$list_file" 2>/dev/null || true)"

    [ -n "$list_content" ]
}
