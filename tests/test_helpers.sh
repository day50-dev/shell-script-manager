#!/usr/bin/env bash
# shurl test helpers

assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" != "$actual" ]]; then
        echo "Assertion failed: expected='$expected', actual='$actual'" >&2
        [[ -n "$message" ]] && echo "Message: $message" >&2
        return 1
    fi
    return 0
}

assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        echo "Assertion failed: expected != actual, but both='$expected'" >&2
        [[ -n "$message" ]] && echo "Message: $message" >&2
        return 1
    fi
    return 0
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Assertion failed: haystack does not contain needle" >&2
        echo "Haystack: $haystack" >&2
        echo "Needle: $needle" >&2
        [[ -n "$message" ]] && echo "Message: $message" >&2
        return 1
    fi
    return 0
}

assert_exit_code() {
    local expected_code="$1"
    local command="$2"
    local message="${3:-}"

    set +e
    eval "$command" > /dev/null 2>&1
    local actual_code=$?
    set -e

    if [[ "$expected_code" != "$actual_code" ]]; then
        echo "Assertion failed: expected exit code='$expected_code', actual='$actual_code'" >&2
        [[ -n "$message" ]] && echo "Message: $message" >&2
        return 1
    fi
    return 0
}

create_test_script() {
    local content="${1:-#!/bin/bash\necho hello}"
    local temp_script
    temp_script="$(mktemp)/test_script.sh"
    mkdir -p "$(dirname "$temp_script")"
    echo "$content" > "$temp_script"
    chmod +x "$temp_script"
    echo "$temp_script"
}

capture_output() {
    local command="$1"
    eval "$command" 2>&1
}

assert_output_contains() {
    local command="$1"
    local expected="$2"
    local message="${3:-}"

    local output
    output="$(eval "$command" 2>&1)"

    if [[ "$output" != *"$expected"* ]]; then
        echo "Assertion failed: output does not contain expected string" >&2
        echo "Expected: $expected" >&2
        echo "Actual: $output" >&2
        [[ -n "$message" ]] && echo "Message: $message" >&2
        return 1
    fi
    return 0
}

assert_output_not_contains() {
    local command="$1"
    local not_expected="$2"
    local message="${3:-}"

    local output
    output="$(eval "$command" 2>&1)"

    if [[ "$output" == *"$not_expected"* ]]; then
        echo "Assertion failed: output contains unexpected string" >&2
        echo "Not expected: $not_expected" >&2
        echo "Actual: $output" >&2
        [[ -n "$message" ]] && echo "Message: $message" >&2
        return 1
    fi
    return 0
}
