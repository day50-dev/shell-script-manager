"""
urshin - Urshi Manifest Generator

A standalone CLI tool that takes a script URL and generates
a complete urshi manifest using multi-pass LLM inference.
"""

__version__ = "0.1.0"
__author__ = "ursh.dev"

from .harness import InferenceHarness
from .cli import main

__all__ = ["InferenceHarness", "main"]
