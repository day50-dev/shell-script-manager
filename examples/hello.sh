#!/usr/bin/env bash
# hello.sh - Example script that demonstrates shurl features

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

show_usage() {
    cat << "EOF"

USAGE EXAMPLES:
  shurl gh:day50-dev/shurl/examples/hello.sh
  shurl gh:day50-dev/shurl/examples/hello.sh "Your Name"
  shurl --dry-run gh:day50-dev/shurl/examples/hello.sh

FEATURES DEMONSTRATED:
  ✓ GitHub shorthand (gh: prefix)
  ✓ Argument passing
  ✓ Heredoc for multi-line output
  ✓ Shell script portability

CACHE LOCATION:
  Linux:   ~/.cache/shurl
  macOS:   ~/Library/Caches/shurl

EOF
}

main() {
    show_logo
    
    echo "👋 Hello from shurl!"
    
    if [[ -n "$1" ]]; then
        echo "   Welcome, $1!"
    fi
    
    echo ""
    echo "📊 This script was executed via:"
    echo "   shurl gh:day50-dev/shurl/examples/hello.sh${1:+ $1}"
    
    echo ""
    echo "🎯 Total arguments: $#"
    
    if [[ $# -gt 0 ]]; then
        echo "   Arguments received:"
        for i in $(seq 1 $#); do
            printf "   %2d. '%s'\n" "$i" "${!i}"
        done
    fi
    
    show_usage
    
    echo "🔍 Try these other examples:"
    echo "   shurl gh:day50-dev/shurl/examples/colors.sh"
    echo "   shurl --dry-run gh:day50-dev/shurl/examples/args.sh"
    echo "   shurl --version"
}

main "$@"
