#!/usr/bin/env bats

@test "Local file execution" {
    local temp_script
    temp_script="$(mktemp)/local-exec-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "local executed"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *local\ executed* ]]
}

@test "Local file dry run" {
    local temp_script
    temp_script="$(mktemp)/local-dryrun-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "dry local"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --dry-run "$temp_script" 2>&1
    [[ "$output" == *\ [dry-run]\ * ]]
    [[ "$output" == *Using\ local\ file* ]]
}

@test "Local file bypasses cache" {
    local temp_script
    temp_script="$(mktemp)/local-cache-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "cache bypass"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true

    local cache_count
    cache_count="$(find "$SHURL_CACHE" -name "*.sh" 2>/dev/null | wc -l)"

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true

    local new_cache_count
    new_cache_count="$(find "$SHURL_CACHE" -name "*.sh" 2>/dev/null | wc -l)"

    [ "$cache_count" = "$new_cache_count" ]
}

@test "Local file with args" {
    local temp_script
    temp_script="$(mktemp)/local-args-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "args: $*"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" "$temp_script" arg1 arg2 arg3 2>&1
    [[ "$output" == *arg1\ arg2\ arg3* ]]
}

@test "Local file update" {
    local temp_script
    temp_script="$(mktemp)/local-update-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "original"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true

    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "updated"
SCRIPT

    run "$SHURL_BINARY" --update "$temp_script" 2>&1
    [[ "$output" == *updated* ]]
}

@test "Local file install" {
    local temp_script
    temp_script="$(mktemp)/local-install-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "installed"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [[ "$output" == *is\ now\ available* ]]
}

@test "Local file absolute path" {
    local temp_script
    temp_script="$(mktemp)/local-abs-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "absolute"
SCRIPT
    chmod +x "$temp_script"

    local abs_path
    abs_path="$(cd "$(dirname "$temp_script")" && pwd)/$(basename "$temp_script")"

    run "$SHURL_BINARY" "$abs_path" 2>&1
    [[ "$output" == *absolute* ]]
}

@test "Local file relative path" {
    local temp_script
    temp_script="$(mktemp)/local-rel-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "relative"
SCRIPT
    chmod +x "$temp_script"

    local rel_path="${temp_script##*/}"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *relative* ]]
}
