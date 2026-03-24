"""
urshin CLI

Command-line interface for generating urshi manifests.
"""

import argparse
import asyncio
import json
import os
import sys

from .harness import InferenceHarness
from .formatters import format_yaml


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        prog="urshin",
        description="Generate urshi manifests from script URLs"
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Create command
    create_parser = subparsers.add_parser(
        "create",
        help="Generate a urshi manifest from a URL"
    )
    create_parser.add_argument(
        "url",
        help="Script URL (e.g., gh:user/repo/script.sh)"
    )
    create_parser.add_argument(
        "-o", "--output",
        choices=["yaml", "json"],
        default="yaml",
        help="Output format (default: yaml)"
    )
    create_parser.add_argument(
        "-O", "--output-file",
        help="Write output to file instead of stdout"
    )
    create_parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show progress and reasoning"
    )
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(0)
    
    if args.command == "create":
        asyncio.run(cmd_create(args))


async def cmd_create(args):
    """Handle 'create' command"""
    # Check for required env vars - NO DEFAULTS
    api_key = os.environ.get("OPENAI_API_KEY")
    base_url = os.environ.get("OPENAI_BASE_URL")
    model = os.environ.get("OPENAI_MODEL")
    brave_key = os.environ.get("BRAVE_API_KEY")
    
    if not api_key:
        print("❌ Error: OPENAI_API_KEY not set", file=sys.stderr)
        print("   Set it in .envrc or export OPENAI_API_KEY=...", file=sys.stderr)
        sys.exit(1)
    
    if not base_url:
        print("❌ Error: OPENAI_BASE_URL not set", file=sys.stderr)
        print("   No default - configure your inference provider", file=sys.stderr)
        print("   Examples:", file=sys.stderr)
        print("     NVIDIA: https://integrate.api.nvidia.com/v1", file=sys.stderr)
        print("     OpenAI: https://api.openai.com/v1", file=sys.stderr)
        print("     Ollama: http://localhost:11434/v1", file=sys.stderr)
        sys.exit(1)
    
    if not model:
        print("❌ Error: OPENAI_MODEL not set", file=sys.stderr)
        print("   No default - choose your model", file=sys.stderr)
        print("   Examples: qwen/qwen3.5-122b-a10b, gpt-4o-mini, llama3.1", file=sys.stderr)
        sys.exit(1)
    
    harness = InferenceHarness(
        api_key=api_key,
        base_url=base_url,
        model=model,
        brave_key=brave_key,
        verbose=args.verbose
    )
    
    if args.verbose:
        print(f"🐚 urshin: Generating manifest for {args.url}")
        print()
    
    # Run inference
    result = await harness.infer(args.url)
    
    if args.verbose:
        print()
        print_progress(result)
    
    # Check for errors
    if result.get("status") == "failed":
        print(f"❌ Inference failed: {result.get('errors', ['Unknown error'])}", file=sys.stderr)
        sys.exit(1)
    
    # Format output
    if args.output == "json":
        output = json.dumps(result["manifest"], indent=2)
    else:
        output = result["manifest_yaml"]
    
    # Write output
    if args.output_file:
        with open(args.output_file, "w") as f:
            f.write(output)
        if args.verbose:
            print(f"✅ Written to {args.output_file}", file=sys.stderr)
    else:
        print(output)
    
    # Exit with appropriate code
    if result.get("status") in ["needs_review", "rejected"]:
        sys.exit(2)


def print_progress(result):
    """Print inference progress"""
    passes = result.get("passes", {})
    
    print("Pass Results:")
    print()
    
    if "homepage" in passes:
        p = passes["homepage"]
        status = "✅" if p and p.get("confidence", 0) > 0.7 else "⚠️"
        print(f"  {status} Homepage: {p.get('value', 'N/A')} ({p.get('confidence', 0):.0%})" if p else "  ⚠️ Homepage: N/A")
    
    if "readme" in passes:
        p = passes["readme"]
        status = "✅" if p and p.get("confidence", 0) > 0.5 else "⚠️"
        if p and p.get('value'):
            val = p['value'][:50] + ('...' if len(p['value']) > 50 else '')
            print(f"  {status} Readme: {val} ({p.get('confidence', 0):.0%})")
        else:
            print(f"  {status} Readme: N/A")
    
    if "name" in passes:
        p = passes["name"]
        status = "✅" if p and p.get("confidence", 0) > 0.7 else "⚠️"
        print(f"  {status} Name: '{p.get('value', 'N/A')}' ({p.get('confidence', 0):.0%})" if p else "  ⚠️ Name: N/A")
    
    if "description" in passes:
        p = passes["description"]
        status = "✅" if p and p.get("confidence", 0) > 0.7 else "⚠️"
        if p and p.get('value'):
            desc = p['value'][:50] + '...'
            print(f"  {status} Description: {desc} ({p.get('confidence', 0):.0%})")
        else:
            print(f"  {status} Description: N/A")
    
    if "source" in passes:
        p = passes["source"]
        status = "✅" if p and p.get("confidence", 0) > 0.5 else "⚠️"
        print(f"  {status} Source: {p.get('value', 'N/A')} ({p.get('confidence', 0):.0%})" if p else "  ⚠️ Source: N/A")
    
    if "license" in passes:
        p = passes["license"]
        status = "✅" if p and p.get("value") else "⚠️"
        print(f"  {status} License: {p.get('value', 'Unknown')} ({p.get('confidence', 0):.0%})" if p else "  ⚠️ License: Unknown")
    
    if "privileges" in passes:
        p = passes["privileges"]
        status = "✅" if p and p.get("confidence", 0) > 0.7 else "⚠️"
        print(f"  {status} Privileges: {p.get('confidence', 0):.0%} confidence" if p else "  ⚠️ Privileges: N/A")
    
    print()
    print(f"Overall Confidence: {result.get('confidence', 0):.0%}")
    print(f"Status: {result.get('status', 'unknown')}")
    
    if result.get("flags"):
        print(f"Flags: {', '.join(result['flags'])}")
    
    print()
