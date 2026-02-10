#!/usr/bin/env bash
# hello.sh - Simple example script for shurl

show_logo() {
    cat << "EOF"

      ____  ___   _     ____________
     / __ \/   | ( )  _/_/ ____/ __ \
    / / / / /| |  V _/_//___ \/ / / /
   / /_/ / ___ |  _/_/ ____/ / /_/ /
  /_____/_/  |_| /_/  /_____/\____/
      Keeping AI Productive
    50 Days In And Beyond

EOF
}

main() {
    show_logo
    
    echo "Hello from shurl! 🚀"
    echo ""
    
    echo "📦 Script Information:"
    echo "  Name: $(basename "$0")"
    echo "  Arguments received: $#"
    
    if [[ $# -gt 0 ]]; then
        echo "  Arguments: $*"
        echo ""
        echo "  Try: shurl --dry-run gh:day50-dev/shurl/examples/hello.sh"
    else
        echo "  No arguments passed"
        echo ""
        echo "  Try: shurl gh:day50-dev/shurl/examples/hello.sh your name here"
    fi
    
    echo ""
    echo "🌍 Environment:"
    echo "  User: $(whoami)"
    echo "  Host: $(hostname)"
    echo "  OS: $(uname -s) $(uname -m)"
    
    echo ""
    echo "💡 Tip: Use 'shurl --dry-run' to preview scripts before running them!"
}

main "$@"
