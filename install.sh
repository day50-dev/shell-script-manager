#!/usr/bin/env bash

# ursh installer
# Usage: curl -fsSL https://raw.githubusercontent.com/day50-dev/ursh/main/install.sh | bash

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
BINARY_NAME="ursh"
REPO_URL="https://github.com/day50-dev/ursh"
INSTALL_DIR="${INSTALL_DIR:-$(detect_install_dir)}"
TEMP_BUILD_DIR=""

# Cleanup
cleanup() {
    if [[ -n "$TEMP_BUILD_DIR" && -d "$TEMP_BUILD_DIR" ]]; then
        rm -rf "$TEMP_BUILD_DIR"
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
    if ! command -v git &>/dev/null; then
        error_exit "git is required to install ursh"
    fi

    if ! command -v go &>/dev/null; then
        error_exit "go is required to build ursh. Please install Go: https://go.dev/doc/install"
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

# Build ursh
build_ursh() {
    info "Building ursh from source..."
    
    TEMP_BUILD_DIR=$(mktemp -d /tmp/ursh-build-XXXXXX)
    
    git clone --depth 1 "$REPO_URL" "$TEMP_BUILD_DIR" || error_exit "Failed to clone repository"
    
    cd "$TEMP_BUILD_DIR/cli" || error_exit "Could not find cli directory in repository"
    
    go build -o "$BINARY_NAME" ./cmd/ursh/main.go ./cmd/ursh/tui.go || error_exit "Failed to build ursh"
    
    if [[ ! -s "$BINARY_NAME" ]]; then
        error_exit "Built binary is empty"
    fi
    
    chmod +x "$BINARY_NAME"
}

# Install ursh
install_ursh() {
    local install_path="$INSTALL_DIR/$BINARY_NAME"
    local source_binary="$TEMP_BUILD_DIR/cli/$BINARY_NAME"
    
    info "Installing to: $install_path"
    
    # Check if already exists
    if [[ -f "$install_path" ]]; then
        warn "ursh already exists at $install_path"
        
        # Compare versions if possible
        if [[ -x "$install_path" ]]; then
            local current_version
            if current_version=$("$install_path" --version 2>/dev/null); then
                info "Current version: $current_version"
            fi
        fi
    fi
    
    # Copy file
    if cp "$source_binary" "$install_path" 2>/dev/null; then
        success "Installed successfully"
    elif sudo cp "$source_binary" "$install_path"; then
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
        success "ursh is available in your PATH"
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
        info "For now, you can run ursh with:"
        echo "  $install_path --version"
    fi
}

# Show usage with dry-run examples
show_usage() {
    echo ""
    info "ursh installation complete!"
    echo ""
    echo "Try it out:"
    echo "  ursh --version"
    echo "  ursh --help"
    echo ""
    echo "Examples with dry-run:"
    echo "  ursh --dry-run gh:day50-dev/ursh/examples/hello.sh"
    echo "  ursh -n https://example.com/script.sh arg1 arg2"
    echo "  ursh --dry-run gh:user/repo@develop/setup.sh"
    echo ""
    echo "Regular usage:"
    echo "  ursh gh:day50-dev/ursh/examples/hello.sh"
    echo "  curl -s https://raw.githubusercontent.com/day50-dev/ursh/main/README.md | sd"
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
    build_ursh
    install_ursh
    check_path
    show_usage
    
    cleanup
}

main "$@"
