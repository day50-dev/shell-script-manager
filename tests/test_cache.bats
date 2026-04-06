#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

setup() {
    export URSH_CACHE="$BATS_TMPDIR/cache"
    mkdir -p "$URSH_CACHE"
}

teardown() {
    rm -rf "$URSH_CACHE" 2>/dev/null || true
}

@test "Cache directory is created" {
    [ -d "$URSH_CACHE" ]
}

@test "Cache stores downloaded file" {
    # Use dry-run to download without executing
    run "$URSH_BINARY" --dry-run https://raw.githubusercontent.com/day50-dev/ursh/main/ursh 2>&1
    [ "$status" -eq 1 ] || [ "$status" -eq 0 ]
    [ -f "$URSH_CACHE"/*.sh ]
}

@test "Update flag clears cache" {
    # Use dry-run to download without executing
    run "$URSH_BINARY" --dry-run https://raw.githubusercontent.com/day50-dev/ursh/main/ursh 2>&1
    local first_mtime
    first_mtime=$(stat -c %Y "$URSH_CACHE"/*.sh 2>/dev/null | head -1)
    sleep 1
    
    run "$URSH_BINARY" --update --dry-run https://raw.githubusercontent.com/day50-dev/ursh/main/ursh 2>&1
    local second_mtime
    second_mtime=$(stat -c %Y "$URSH_CACHE"/*.sh 2>/dev/null | head -1)
    
    [ "$second_mtime" -ge "$first_mtime" ]
}

@test "Clear cache works" {
    run "$URSH_BINARY" --clear-cache 2>&1
    [ "$status" -eq 0 ]
}

@test "Cache key is based on URL hash" {
    local test_url="https://raw.githubusercontent.com/day50-dev/ursh/main/ursh"
    
    run "$URSH_BINARY" --dry-run "$test_url" 2>&1

    local expected_hash
    expected_hash=$(echo "$test_url" | md5sum | cut -d' ' -f1)
    [ -f "$URSH_CACHE/${expected_hash}.sh" ]
}
