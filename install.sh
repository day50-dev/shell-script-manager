#!/usr/bin/env bash

# ursh installer
# Usage: curl -fsSL https://raw.githubusercontent.com/day50-dev/ursh/main/install.sh | bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BINARY_NAME="ursh"
REPO="day50-dev/ursh"
INSTALL_DIR="${PREFIX:-${INSTALL_DIR:-}}"
TEMP_DIR=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

success() { echo -e "${GREEN}$1${NC}"; }
info()    { echo -e "${BLUE}$1${NC}"; }
warn()    { echo -e "${YELLOW}$1${NC}"; }
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    cleanup
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT
trap 'echo -e "\n${RED}Installation cancelled${NC}"; cleanup; exit 1' INT TERM

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

detect_platform() {
    local os arch

    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Linux)  os="linux"  ;;
        Darwin) os="darwin" ;;
        *)
            warn "Unsupported OS: $os"
            os=""
            ;;
    esac

    case "$arch" in
        x86_64)          arch="amd64" ;;
        aarch64|arm64)   arch="arm64" ;;
        *)
            warn "Unsupported architecture: $arch"
            arch=""
            ;;
    esac

    PLATFORM_OS="$os"
    PLATFORM_ARCH="$arch"
}

# ---------------------------------------------------------------------------
# Install directory
# ---------------------------------------------------------------------------

detect_install_dir() {
    if [[ -n "$INSTALL_DIR" ]]; then
        return
    fi

    if [[ -d "$HOME/.local/bin" && -w "$HOME/.local/bin" ]]; then
        INSTALL_DIR="$HOME/.local/bin"
    elif [[ -d "/usr/local/bin" && -w "/usr/local/bin" ]]; then
        INSTALL_DIR="/usr/local/bin"
    else
        INSTALL_DIR="$HOME/.local/bin"
    fi
}

# ---------------------------------------------------------------------------
# Download helpers
# ---------------------------------------------------------------------------

download_file() {
    local url="$1" dest="$2"
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &>/dev/null; then
        wget -qO "$dest" "$url"
    else
        error_exit "curl or wget is required to download ursh"
    fi
}

# ---------------------------------------------------------------------------
# Verify checksum (best-effort)
# ---------------------------------------------------------------------------

verify_checksum() {
    local archive="$1" checksums_file="$2" archive_name
    archive_name="$(basename "$archive")"

    local expected
    expected="$(grep "$archive_name" "$checksums_file" | awk '{print $1}')" || true
    if [[ -z "$expected" ]]; then
        warn "No checksum entry found for $archive_name – skipping verification"
        return 0
    fi

    local actual
    if command -v sha256sum &>/dev/null; then
        actual="$(sha256sum "$archive" | awk '{print $1}')"
    elif command -v shasum &>/dev/null; then
        actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
    else
        warn "sha256sum / shasum not found – skipping checksum verification"
        return 0
    fi

    if [[ "$actual" != "$expected" ]]; then
        error_exit "Checksum mismatch for $archive_name\n  expected: $expected\n  got:      $actual"
    fi
    success "Checksum verified ✓"
}

# ---------------------------------------------------------------------------
# Try to install from prebuilt GitHub Release binary
# ---------------------------------------------------------------------------

install_from_release() {
    [[ -z "$PLATFORM_OS" || -z "$PLATFORM_ARCH" ]] && return 1

    info "Fetching latest release information..."

    local latest_url="https://api.github.com/repos/${REPO}/releases/latest"
    local release_json tag_name

    TEMP_DIR="$(mktemp -d /tmp/ursh-install-XXXXXX)"

    release_json="$TEMP_DIR/release.json"
    if ! download_file "$latest_url" "$release_json" 2>/dev/null; then
        warn "Could not reach GitHub API"
        return 1
    fi

    # Parse tag_name with minimal tooling (avoid jq dependency)
    tag_name="$(grep -m1 '"tag_name"' "$release_json" | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')" || true
    if [[ -z "$tag_name" ]]; then
        warn "Could not determine latest release tag"
        return 1
    fi

    local archive_name="ursh_${tag_name}_${PLATFORM_OS}_${PLATFORM_ARCH}.tar.gz"
    local base_url="https://github.com/${REPO}/releases/download/${tag_name}"
    local archive_url="${base_url}/${archive_name}"
    local checksums_url="${base_url}/checksums.txt"

    info "Downloading ${archive_name}..."
    if ! download_file "$archive_url" "$TEMP_DIR/${archive_name}" 2>/dev/null; then
        warn "Prebuilt binary not available for ${PLATFORM_OS}/${PLATFORM_ARCH} (tag: ${tag_name})"
        return 1
    fi

    # Download and verify checksums (best-effort)
    if download_file "$checksums_url" "$TEMP_DIR/checksums.txt" 2>/dev/null; then
        verify_checksum "$TEMP_DIR/${archive_name}" "$TEMP_DIR/checksums.txt"
    else
        warn "Could not download checksums.txt – skipping checksum verification"
    fi

    info "Extracting archive..."
    if ! tar -xzf "$TEMP_DIR/${archive_name}" -C "$TEMP_DIR" ursh 2>/dev/null; then
        warn "Failed to extract binary from archive: ${archive_name}"
        return 1
    fi

    install_binary "$TEMP_DIR/ursh"
    return 0
}

# ---------------------------------------------------------------------------
# Fallback: go install
# ---------------------------------------------------------------------------

install_from_go() {
    if ! command -v go &>/dev/null; then
        return 1
    fi

    info "Falling back to: go install github.com/${REPO}/go/cmd/ursh@latest"
    GOBIN="$INSTALL_DIR" go install "github.com/${REPO}/go/cmd/ursh@latest" || return 1
    return 0
}

# ---------------------------------------------------------------------------
# Place the binary
# ---------------------------------------------------------------------------

install_binary() {
    local src="$1"
    local dest="$INSTALL_DIR/$BINARY_NAME"

    chmod +x "$src"

    if [[ -f "$dest" ]]; then
        warn "Replacing existing ursh at $dest"
    fi

    if cp "$src" "$dest" 2>/dev/null; then
        chmod +x "$dest"
        success "Installed ursh → $dest"
    elif sudo cp "$src" "$dest" && sudo chmod +x "$dest"; then
        success "Installed ursh → $dest (via sudo)"
    else
        error_exit "Failed to install to $dest"
    fi
}

# ---------------------------------------------------------------------------
# PATH reminder
# ---------------------------------------------------------------------------

check_path() {
    if command -v "$BINARY_NAME" &>/dev/null; then
        success "ursh is available in your PATH"
        return
    fi

    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "$INSTALL_DIR is not in your PATH"
        echo ""
        echo "Add it to your shell config (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "Then reload: source ~/.bashrc  # or ~/.zshrc"
        echo ""
        info "For now, run ursh directly with:"
        echo "    $INSTALL_DIR/$BINARY_NAME --version"
    fi
}

# ---------------------------------------------------------------------------
# Banner + main
# ---------------------------------------------------------------------------

print_banner() {
    cat << 'ENDL'
      ____  ___   _     ____________
     / __ \/   | ( )  _/_/ ____/ __ \
    / / / / /| |  V _/_//___ \/ / / /
   / /_/ / ___ |  _/_/ ____/ / /_/ /
  /_____/_/  |_| /_/  /_____/\____/

      Keeping AI Productive
    50 Days In And Beyond

ENDL
}

main() {
    print_banner

    detect_platform
    detect_install_dir

    info "OS:              ${PLATFORM_OS:-unknown}"
    info "Architecture:    ${PLATFORM_ARCH:-unknown}"
    info "Install dir:     $INSTALL_DIR"
    echo ""

    if [[ ! -d "$INSTALL_DIR" ]]; then
        info "Creating $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR" || error_exit "Failed to create $INSTALL_DIR"
    fi

    # 1. Try prebuilt binary from GitHub Releases
    if install_from_release; then
        true
    # 2. Fallback: go install
    elif install_from_go; then
        true
    else
        error_exit "Installation failed.\n\nOptions:\n  - Install Go and re-run this script, or\n  - Download a prebuilt binary from https://github.com/${REPO}/releases"
    fi

    echo ""
    check_path
    echo ""
    success "Installation complete!"
    echo ""
    echo "Try it out:"
    echo "  ursh --version"
    echo "  ursh --help"
    echo "  ursh --dry-run gh:day50-dev/ursh/examples/hello.sh"
    echo ""
    echo "Documentation: https://github.com/${REPO}"
}

main "$@"
