#!/usr/bin/env bats

SHURL_BINARY="/home/chris/code/shurl/shurl"

setup() {
    export HOME="$BATS_TMPDIR/home"
    mkdir -p "$HOME/.local/bin"
}

teardown() {
    rm -rf "$BATS_TMPDIR/home" 2>/dev/null || true
}

@test "Install creates file in ~/.local/bin" {
    local temp_script="$BATS_TMPDIR/install-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "installed"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [ "$status" -eq 0 ]
    [ -f "$HOME/.local/bin/install-test" ]
}

@test "Install makes file executable" {
    local temp_script="$BATS_TMPDIR/exec-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "exec"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true
    [ -x "$HOME/.local/bin/exec-test" ]
}

@test "Install with dry-run" {
    local temp_script="$BATS_TMPDIR/dry-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "dry"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --dry-run --install "$temp_script" 2>&1
    [[ "$output" == *"[dry-run]"* ]]
    [ ! -f "$HOME/.local/bin/dry-test" ]
}

@test "Install shows message" {
    local temp_script="$BATS_TMPDIR/msg-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "msg"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [[ "$output" == *"is now available"* ]]
}

@test "Install with update" {
    local temp_script="$BATS_TMPDIR/up-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "v1"
SCRIPT
    chmod +x "$temp_script"

    "$SHURL_BINARY" --install "$temp_script" 2>/dev/null || true

    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "v2"
SCRIPT

    run "$SHURL_BINARY" --update --install "$temp_script" 2>&1
    [[ "$output" == *"is now available"* ]]
}

@test "Install with local file" {
    local temp_script="$BATS_TMPDIR/local-test.sh"
    cat > "$temp_script" << 'SCRIPT'
#!/bin/bash
echo "local"
SCRIPT
    chmod +x "$temp_script"

    run "$SHURL_BINARY" --install "$temp_script" 2>&1
    [ "$status" -eq 0 ]
}
