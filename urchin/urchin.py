#!/usr/bin/env python3
"""
urchin - Generate urshi manifests from script URLs

Usage:
    python urchin.py <url> [options]

Example:
    python urchin.py gh:user/repo/script.sh
"""

import sys
import os

# Add the project root to the path so we can import urshin
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from urshin.cli import main

if __name__ == "__main__":
    main()
