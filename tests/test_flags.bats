#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

@test "version flag shows version" {
    run "$URSH_BINARY" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"ursh v"* ]]
}

@test "help flag shows usage" {
    run "$URSH_BINARY" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ursh"* ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "clear-cache flag runs without error" {
    run "$URSH_BINARY" --clear-cache
    [ "$status" -eq 0 ]
}

@test "dry-run flag shows marker" {
    run "$URSH_BINARY" --dry-run https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "update non-existent URL errors" {
    run "$URSH_BINARY" --update https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "install non-existent URL errors" {
    run "$URSH_BINARY" --install https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "list shows empty state" {
    run "$URSH_BINARY" --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"No installed packages"* ]]
}

@test "combined flags -nu work" {
    run "$URSH_BINARY" -nu https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "combined flags -iu work" {
    run "$URSH_BINARY" -iu https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "combined flags -nuq work" {
    run "$URSH_BINARY" -nuq https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "short version flag works" {
    run "$URSH_BINARY" -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"ursh v"* ]]
}

@test "short list flag works" {
    run "$URSH_BINARY" -l
    [ "$status" -eq 0 ]
    [[ "$output" == *"No installed packages"* ]]
}
