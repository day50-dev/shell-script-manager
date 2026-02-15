#!/usr/bin/env bats

SHURL_BINARY="/home/chris/code/shurl/shurl"

@test "version flag shows version" {
    run "$SHURL_BINARY" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"shurl v"* ]]
}

@test "help flag shows usage" {
    run "$SHURL_BINARY" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"shurl"* ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "clear-cache flag runs without error" {
    run "$SHURL_BINARY" --clear-cache
    [ "$status" -eq 0 ]
}

@test "dry-run flag shows marker" {
    run "$SHURL_BINARY" --dry-run https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "update non-existent URL errors" {
    run "$SHURL_BINARY" --update https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "install non-existent URL errors" {
    run "$SHURL_BINARY" --install https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "list shows empty state" {
    run "$SHURL_BINARY" --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"No installed packages"* ]]
}

@test "combined flags -nu work" {
    run "$SHURL_BINARY" -nu https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "combined flags -iu work" {
    run "$SHURL_BINARY" -iu https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]]
}

@test "combined flags -nuq work" {
    run "$SHURL_BINARY" -nuq https://example.com/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "short version flag works" {
    run "$SHURL_BINARY" -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"shurl v"* ]]
}

@test "short list flag works" {
    run "$SHURL_BINARY" -l
    [ "$status" -eq 0 ]
    [[ "$output" == *"No installed packages"* ]]
}
