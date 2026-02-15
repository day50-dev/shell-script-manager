#!/usr/bin/env bash
# Test flag parsing

source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

test_version_flag() {
    local output
    output="$("$SHURL_BINARY" --version)"
    assert_contains "$output" "shurl v" "Version flag should show version"
}

test_help_flag() {
    local output
    output="$("$SHURL_BINARY" --help)"
    assert_contains "$output" "shurl" "Help should mention shurl"
    assert_contains "$output" "Usage:" "Help should show usage"
}

test_clear_cache_flag() {
    "$SHURL_BINARY" --clear-cache
}

test_dry_run_flag() {
    local output
    output="$("$SHURL_BINARY" --dry-run https://example.com/script.sh 2>&1)" || true
    assert_contains "$output" "[dry-run]" "Dry run should show marker"
}

test_update_flag() {
    local output
    output="$("$SHURL_BINARY" --update https://example.com/script.sh 2>&1)" || true
    assert_contains "$output" "error" "Update non-existent URL should error"
}

test_install_flag() {
    local output
    output="$("$SHURL_BINARY" --install https://example.com/script.sh 2>&1)" || true
    assert_contains "$output" "error" "Install non-existent URL should error"
}

test_list_flag() {
    local output
    output="$("$SHURL_BINARY" --list)"
    assert_contains "$output" "No installed packages" "List should handle empty state"
}

test_combined_flags_nu() {
    local output
    output="$("$SHURL_BINARY" -nu https://example.com/script.sh 2>&1)" || true
    assert_contains "$output" "[dry-run]" "Combined flags should work"
}

test_combined_flags_iu() {
    local output
    output="$("$SHURL_BINARY" -iu https://example.com/script.sh 2>&1)" || true
    assert_contains "$output" "[dry-run]" "Combined flags should work"
}

test_combined_flags_nuq() {
    local output
    output="$("$SHURL_BINARY" -nuq https://example.com/script.sh 2>&1)" || true
    assert_contains "$output" "[dry-run]" "Combined flags should work"
}

test_short_version_flag() {
    local output
    output="$("$SHURL_BINARY" -v)"
    assert_contains "$output" "shurl v" "Short version flag should work"
}

test_short_list_flag() {
    local output
    output="$("$SHURL_BINARY" -l)"
    assert_contains "$output" "No installed packages" "Short list flag should work"
}
