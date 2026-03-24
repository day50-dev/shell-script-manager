#!/usr/bin/env bats

URSH_BINARY="${URSH:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ursh}"

setup() {
    export BATS_TMPDIR="${BATS_TMPDIR:-/tmp/bats-$$}"
    mkdir -p "$BATS_TMPDIR"
}

# Helper to create a test script
create_test_script() {
    local name="$1"
    local script_path="$BATS_TMPDIR/${name}.sh"
    cat > "$script_path" << 'SCRIPT'
#!/bin/sh
echo "test script"
SCRIPT
    chmod +x "$script_path"
    echo "$script_path"
}

@test "guard without type shows error" {
    run "$URSH_BINARY" --guard 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"requires a type"* ]]
}

@test "guard with invalid type shows error" {
    run "$URSH_BINARY" --guard invalid gh:user/repo/script.sh 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown guard type"* ]]
}

@test "guard chroot with dry-run shows expected output" {
    local script_path
    script_path=$(create_test_script "chroot-test")
    run "$URSH_BINARY" --dry-run --guard chroot "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"chroot"* ]]
}

@test "guard docker with dry-run shows expected output" {
    local script_path
    script_path=$(create_test_script "docker-test")
    run "$URSH_BINARY" --dry-run --guard docker "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"docker"* ]]
    [[ "$output" == *"alpine"* ]]
}

@test "guard docker with custom image in dry-run" {
    local script_path
    script_path=$(create_test_script "custom-img")
    run "$URSH_BINARY" --dry-run --guard docker --docker-image ubuntu:22.04 "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"ubuntu:22.04"* ]]
}

@test "guard chroot with custom root in dry-run" {
    local script_path
    script_path=$(create_test_script "custom-root")
    run "$URSH_BINARY" --dry-run --guard chroot --chroot-root /custom/path "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"/custom/path"* ]]
}

@test "guard combined with install flag" {
    local script_path
    script_path=$(create_test_script "guard-install")
    run "$URSH_BINARY" --dry-run --guard docker --install "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"directory"* ]]
}

@test "guard requires script URL" {
    run "$URSH_BINARY" --guard chroot 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"No URL provided"* ]] || [[ "$output" == *"error"* ]]
}

@test "guard with local file shows script path" {
    local script_path
    script_path=$(create_test_script "local-guard")
    run "$URSH_BINARY" --dry-run --guard docker "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"docker"* ]]
}

@test "guard combined short flags -nu" {
    local script_path
    script_path=$(create_test_script "combined-flags")
    run "$URSH_BINARY" -nu --guard docker "$script_path" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"docker"* ]]
}