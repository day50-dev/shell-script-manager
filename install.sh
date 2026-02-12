#!/usr/bin/env bash

# shurl installer
# Usage: curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/install.sh | bash

set -euo pipefail

# Version
VERSION="1.1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS and set install directory
detect_install_dir() {
    local os_name
    os_name="$(uname -s)"
    
    case "$os_name" in
        Darwin*)
            # macOS: prefer ~/.local/bin, fallback to /usr/local/bin
            if [[ -d "$HOME/.local/bin" && -w "$HOME/.local/bin" ]]; then
                echo "$HOME/.local/bin"
            elif [[ -d "/usr/local/bin" ]]; then
                echo "/usr/local/bin"
            else
                echo "$HOME/.local/bin"
            fi
            ;;
        Linux*|*BSD*)
            # Linux/BSD: XDG bin directory, fallback to system
            if [[ -d "$HOME/.local/bin" && -w "$HOME/.local/bin" ]]; then
                echo "$HOME/.local/bin"
            elif [[ -d "/usr/local/bin" ]]; then
                echo "/usr/local/bin"
            else
                echo "$HOME/.local/bin"
            fi
            ;;
        *)
            # Other: fallback to ~/.local/bin
            echo "$HOME/.local/bin"
            ;;
    esac
}

# Defaults
BINARY_NAME="shurl"
REPO_URL="https://github.com/day50-dev/shurl"
RAW_URL="https://raw.githubusercontent.com/day50-dev/shurl/main/shurl"
INSTALL_DIR="${INSTALL_DIR:-$(detect_install_dir)}"
TEMP_FILE=""

# Cleanup
cleanup() {
    if [[ -n "$TEMP_FILE" && -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

# Error handler
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    cleanup
    exit 1
}

# Messages
success() { echo -e "${GREEN}$1${NC}"; }
info() { echo -e "${BLUE}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }

# Check requirements
check_requirements() {
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        error_exit "curl or wget is required to install shurl"
    fi
    
    info "Detected OS: $(uname -s)"
    info "Install directory: $INSTALL_DIR"
    
    # Ensure install directory exists
    if [[ ! -d "$INSTALL_DIR" ]]; then
        info "Creating directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR" || error_exit "Failed to create $INSTALL_DIR"
    fi
    
    # Check write permissions
    if [[ ! -w "$INSTALL_DIR" ]]; then
        warn "Directory $INSTALL_DIR is not writable"
        echo "We'll try to use sudo for installation"
    fi
}

# Download shurl
download_shurl() {
    info "Downloading shurl from GitHub..."
    
    TEMP_FILE=$(mktemp /tmp/shurl-install-XXXXXX)
    
    if command -v curl &>/dev/null; then
        curl -fsSL "$RAW_URL" -o "$TEMP_FILE" || error_exit "Failed to download shurl"
    elif command -v wget &>/dev/null; then
        wget -qO "$TEMP_FILE" "$RAW_URL" || error_exit "Failed to download shurl"
    fi
    
    if [[ ! -s "$TEMP_FILE" ]]; then
        error_exit "Downloaded file is empty"
    fi
    
    chmod +x "$TEMP_FILE" || error_exit "Failed to make executable"
    
    # Verify it's bash
    if ! head -n 1 "$TEMP_FILE" | grep -q "bash"; then
        error_exit "Downloaded file doesn't appear to be a bash script"
    fi
}

# Install shurl
install_shurl() {
    local install_path="$INSTALL_DIR/$BINARY_NAME"
    
    info "Installing to: $install_path"
    
    # Check if already exists
    if [[ -f "$install_path" ]]; then
        warn "shurl already exists at $install_path"
        
        # Compare versions if possible
        if [[ -x "$install_path" ]]; then
            local current_version
            if current_version=$("$install_path" --version 2>/dev/null); then
                info "Current version: $current_version"
            fi
        fi
    fi
    
    # Copy file
    if cp "$TEMP_FILE" "$install_path" 2>/dev/null; then
        success "Installed successfully"
    elif sudo cp "$TEMP_FILE" "$install_path"; then
        success "Installed with sudo"
    else
        error_exit "Failed to install to $install_path"
    fi
    
    # Ensure executable
    if [[ -w "$install_path" ]]; then
        chmod +x "$install_path" || warn "Could not set executable bit (but may already be executable)"
    else
        sudo chmod +x "$install_path" || warn "Could not set executable bit with sudo"
    fi
}

# Add to PATH if needed
check_path() {
    local install_path="$INSTALL_DIR/$BINARY_NAME"
    
    # Check if in PATH
    if command -v "$BINARY_NAME" &>/dev/null; then
        success "shurl is available in your PATH"
        return
    fi
    
    # Check if the install directory is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "Note: $INSTALL_DIR is not in your PATH"
        echo ""
        
        case "$(uname -s)" in
            Darwin*)
                cat << EOF
To add it to your PATH, add this to your ~/.zshrc or ~/.bash_profile:

    export PATH="\$HOME/.local/bin:\$PATH"

Then run:
    source ~/.zshrc  # or ~/.bash_profile
EOF
                ;;
            Linux*|*BSD*)
                cat << EOF
To add it to your PATH, add this to your ~/.bashrc or ~/.zshrc:

    export PATH="\$HOME/.local/bin:\$PATH"

Then run:
    source ~/.bashrc  # or ~/.zshrc
EOF
                ;;
        esac
        
        echo ""
        info "For now, you can run shurl with:"
        echo "  $install_path --version"
    fi
}

# Show usage with dry-run examples
show_usage() {
    echo ""
    info "shurl installation complete!"
    echo ""
    echo "Try it out:"
    echo "  shurl --version"
    echo "  shurl --help"
    echo ""
    echo "Examples with dry-run:"
    echo "  shurl --dry-run gh:day50-dev/shurl/examples/hello.sh"
    echo "  shurl -n https://example.com/script.sh arg1 arg2"
    echo "  shurl --dry-run gh:user/repo@develop/setup.sh"
    echo ""
    echo "Regular usage:"
    echo "  shurl gh:day50-dev/shurl/examples/hello.sh"
    echo "  shurl https://raw.githubusercontent.com/day50-dev/shurl/main/README.md"
    echo ""
    echo "Documentation: $REPO_URL"
}

# Main
main() {
     cat << ENDL
      ____  ___   _     ____________
     / __ \/   | ( )  _/_/ ____/ __ \\
    / / / / /| |  V _/_//___ \/ / / /
   / /_/ / ___ |  _/_/ ____/ / /_/ /
  /_____/_/  |_| /_/  /_____/\____/

      Keeping AI Productive
    50 Days In And Beyond

ENDL
    
    trap cleanup EXIT
    trap 'echo -e "\n${RED}Installation cancelled${NC}"; cleanup; exit 1' INT
    
    check_requirements
    download_shurl
    install_shurl
    check_path
    show_usage
    
    cleanup
}

main "$@"
