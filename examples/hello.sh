#!/usr/bin/env bash
# hello.sh - Example script that demonstrates ursh features

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
  ursh gh:day50-dev/ursh/examples/hello.sh
  ursh gh:day50-dev/ursh/examples/hello.sh "Your Name"
  ursh --dry-run gh:day50-dev/ursh/examples/hello.sh

FEATURES DEMONSTRATED:
  ✓ GitHub shorthand (gh: prefix)
  ✓ Argument passing
  ✓ Heredoc for multi-line output
  ✓ Shell script portability

CACHE LOCATION:
  Linux:   ~/.cache/ursh
  macOS:   ~/Library/Caches/ursh

EOF
}

main() {
    show_logo
    
    echo "👋 Hello from ursh!"
    
    if [[ -n "$1" ]]; then
        echo "   Welcome, $1!"
    fi
    
    echo ""
    echo "📊 This script was executed via:"
    echo "   ursh gh:day50-dev/ursh/examples/hello.sh${1:+ $1}"
    
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
    echo "   ursh gh:day50-dev/ursh/examples/colors.sh"
    echo "   ursh --dry-run gh:day50-dev/ursh/examples/args.sh"
    echo "   ursh --version"
}

main "$@"
