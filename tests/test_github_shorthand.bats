#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

setup() {
    # Create isolated temp cache for each test
    export URSH_CACHE=$(mktemp -d)
}

teardown() {
    # Clean up temp cache
    rm -rf "$URSH_CACHE"
}

@test "GitHub shorthand basic" {
    run "$URSH_BINARY" gh:user/repo/file.sh 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand with branch" {
    run "$URSH_BINARY" gh:user/repo@develop/file.sh 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand with tag" {
    run "$URSH_BINARY" gh:user/repo@v1.2.3/file.sh 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand repo only" {
    # Repo-only expands to repo/repo (common pattern)
    run "$URSH_BINARY" --dry-run gh:day50-dev/ursh 2>&1
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
    [[ "$output" == *"raw.githubusercontent.com/day50-dev/ursh/main/ursh"* ]]
}

@test "GitHub shorthand invalid" {
    run "$URSH_BINARY" gh:invalid 2>&1
    [[ "$output" == *"Invalid GitHub shorthand"* ]]
}

@test "GitHub shorthand user only" {
    run "$URSH_BINARY" gh:user 2>&1
    [[ "$output" == *"Invalid GitHub shorthand"* ]]
}

@test "GitHub shorthand valid expansion with dry-run" {
    run "$URSH_BINARY" --dry-run gh:day50-dev/ursh/examples/hello.sh 2>&1
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"raw.githubusercontent.com/day50-dev/ursh/main/examples/hello.sh"* ]]
}

@test "GitHub shorthand with explicit branch" {
    run "$URSH_BINARY" --dry-run gh:day50-dev/ursh@main/examples/hello.sh 2>&1
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"raw.githubusercontent.com/day50-dev/ursh/main/examples/hello.sh"* ]]
}
