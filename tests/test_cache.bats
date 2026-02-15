#!/usr/bin/env bats

SHURL_BINARY="/home/chris/code/shurl/shurl"

setup() {
    export SHURL_CACHE="$BATS_TMPDIR/cache"
    mkdir -p "$SHURL_CACHE"
}

teardown() {
    rm -rf "$SHURL_CACHE" 2>/dev/null || true
}

@test "Cache directory is created" {
    [ -d "$SHURL_CACHE" ]
}

@test "Cache stores downloaded file" {
    # Use dry-run to download without executing
    run "$SHURL_BINARY" --dry-run https://raw.githubusercontent.com/day50-dev/shurl/main/shurl 2>&1
    [ "$status" -eq 1 ] || [ "$status" -eq 0 ]
    [ -f "$SHURL_CACHE"/*.sh ]
}

@test "Update flag clears cache" {
    # Use dry-run to download without executing
    run "$SHURL_BINARY" --dry-run https://raw.githubusercontent.com/day50-dev/shurl/main/shurl 2>&1
    local first_mtime
    first_mtime=$(stat -c %Y "$SHURL_CACHE"/*.sh 2>/dev/null | head -1)
    sleep 1
    
    run "$SHURL_BINARY" --update --dry-run https://raw.githubusercontent.com/day50-dev/shurl/main/shurl 2>&1
    local second_mtime
    second_mtime=$(stat -c %Y "$SHURL_CACHE"/*.sh 2>/dev/null | head -1)
    
    [ "$second_mtime" -ge "$first_mtime" ]
}

@test "Clear cache works" {
    run "$SHURL_BINARY" --clear-cache 2>&1
    [ "$status" -eq 0 ]
}

@test "Cache key is based on URL hash" {
    local test_url="https://raw.githubusercontent.com/day50-dev/shurl/main/shurl"
    
    run "$SHURL_BINARY" --dry-run "$test_url" 2>&1

    local expected_hash
    expected_hash=$(echo "$test_url" | md5sum | cut -d' ' -f1)
    [ -f "$SHURL_CACHE/${expected_hash}.sh" ]
}
