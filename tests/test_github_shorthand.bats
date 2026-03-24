#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

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
    run "$URSH_BINARY" gh:user/repo 2>&1
    [[ "$output" == *"error"* ]]
}

@test "GitHub shorthand invalid" {
    run "$URSH_BINARY" gh:invalid 2>&1
    [[ "$output" == *"Invalid GitHub shorthand"* ]]
}

@test "GitHub shorthand user only" {
    run "$URSH_BINARY" gh:user 2>&1
    [[ "$output" == *"Invalid GitHub shorthand"* ]]
}
