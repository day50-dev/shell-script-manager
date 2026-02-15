#!/usr/bin/env bats

@test "GitHub shorthand basic" {
    run "$SHURL_BINARY" gh:user/repo/file.sh 2>&1
    [[ "$output" == *error* ]]
}

@test "GitHub shorthand with branch" {
    run "$SHURL_BINARY" gh:user/repo@develop/file.sh 2>&1
    [[ "$output" == *error* ]]
}

@test "GitHub shorthand with tag" {
    run "$SHURL_BINARY" gh:user/repo@v1.2.3/file.sh 2>&1
    [[ "$output" == *error* ]]
}

@test "GitHub shorthand repo only" {
    run "$SHURL_BINARY" gh:user/repo 2>&1
    [[ "$output" == *error* ]]
}

@test "GitHub shorthand invalid format" {
    run "$SHURL_BINARY" gh:invalid 2>&1
    [[ "$output" == *Invalid\ GitHub\ shorthand* ]]
}

@test "GitHub shorthand no slash" {
    run "$SHURL_BINARY" gh:user 2>&1
    [[ "$output" == *Invalid\ GitHub\ shorthand* ]]
}
