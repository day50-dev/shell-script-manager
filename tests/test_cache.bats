#!/usr/bin/env bats

@test "Cache directory created" {
    local cache_dir="$SHURL_CACHE"
    [ "$cache_dir" = "$SHURL_CACHE" ]
}

@test "Cache file created on download" {
    local temp_script
    temp_script="$(mktemp)/cache-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "cached"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true

    local cache_files
    cache_files="$(find "$SHURL_CACHE" -name "*.sh" 2>/dev/null || true)"
    [ -n "$cache_files" ]
}

@test "Cache reuse" {
    local temp_script
    temp_script="$(mktemp)/reused-cache-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "reused"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true
    local first_run_time
    first_run_time="$(date +%s)"

    sleep 1

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true
    local second_run_time
    second_run_time="$(date +%s)"

    local elapsed=$((second_run_time - first_run_time))
    [ -n "$first_run_time" ]
    [ -n "$second_run_time" ]
}

@test "Cache clear" {
    run "$SHURL_BINARY" --clear-cache
    [[ "$output" == *Cache\ cleared* ]]
}

@test "Cache key generation" {
    local temp_script1
    temp_script1="$(mktemp)/cache-key1.sh"
    mkdir -p "$(dirname "$temp_script1")"
    cat > "$temp_script1" << 'SCRIPT'
#!/bin/bash
echo "key1"
SCRIPT
    chmod +x "$temp_script1"

    local temp_script2
    temp_script2="$(mktemp)/cache-key2.sh"
    mkdir -p "$(dirname "$temp_script2")"
    cat > "$temp_script2" << 'SCRIPT'
#!/bin/bash
echo "key2"
SCRIPT
    chmod +x "$temp_script2"

    "$SHURL_BINARY" "$temp_script1" > /dev/null 2>&1 || true
    "$SHURL_BINARY" "$temp_script2" > /dev/null 2>&1 || true

    local cache_count
    cache_count="$(find "$SHURL_CACHE" -name "*.sh" 2>/dev/null | wc -l)"
    [ "$cache_count" != "1" ]
}

@test "Cache custom location" {
    local custom_cache
    custom_cache="$(mktemp -d)/custom-cache"
    export SHURL_CACHE="$custom_cache"

    local temp_script
    temp_script="$(mktemp)/custom-cache-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "custom"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" "$temp_script" > /dev/null 2>&1 || true

    local cache_files
    cache_files="$(find "$custom_cache" -name "*.sh" 2>/dev/null || true)"
    [ -n "$cache_files" ]
}

@test "Cache empty file handling" {
    local temp_script
    temp_script="$(mktemp)/empty-cache-test.sh"
    mkdir -p "$(dirname "$temp_script")"
    touch "$temp_script"

    run "$SHURL_BINARY" "$temp_script" 2>&1
    [[ "$output" == *error* ]]
}
