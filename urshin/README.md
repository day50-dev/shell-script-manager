# urshin - Standalone Manifest Generator

**Generate urshi manifests from script URLs using multi-pass LLM inference.**

## What is urshin?

urshin is a standalone CLI tool that takes a single script URL and generates a complete urshi manifest. It uses **sequential bootstrap inference** where each pass builds on previously discovered information.

## Installation

```bash
cd urshin
uv sync
direnv allow  # Loads environment
```

## Usage

```bash
# Basic usage
urshin create gh:user/repo/script.sh

# Verbose output
urshin create https://cursor.com/install --verbose

# Output to file
urshin create gh:user/repo/script.sh -O manifest.urshi.yaml
```

## How It Works

urshin uses a multi-pass inference pipeline:

1. **Pass 1: Homepage** - Infer homepage from URL structure
2. **Pass 2: Readme** - Find README/documentation URL
3. **Pass 3: Name** - Infer descriptive project name (NOT generic like "install")
4. **Pass 4: Source** - Find source code repository
5. **Pass 5: License** - Detect license type
6. **Pass 6: Compliances** - Find compliance certifications
7. **Pass 7: Privileges** - Analyze script with surface area scopes

Each pass uses web search (Brave) + LLM inference with cross-validation.

## Tool Scopes (Surface Area)

urshin reports **meaningful scopes** for each tool, not just "external tool":

| Bad (useless) | Good (surface area) |
|--------------|---------------------|
| `{"name": "rm", "scope": "external tool"}` | `{"name": "rm", "scope": "removes temp files in /tmp", "risk": "low"}` |
| `{"name": "cat", "scope": "file operations"}` | `{"name": "cat", "scope": "reads ~/.bashrc to append PATH", "risk": "medium"}` |
| `{"name": "curl", "scope": "network"}` | `{"name": "curl", "scope": "downloads from downloads.cursor.com (trusted)", "risk": "low"}` |

## Environment Variables

Required (no defaults):
- `OPENAI_API_KEY` - Your API key
- `OPENAI_BASE_URL` - Inference provider URL
- `OPENAI_MODEL` - Model to use

Optional:
- `BRAVE_API_KEY` - For web search
- `BROWSER` - Headless browser command
- `HTMLTOMARKDOWN` - HTML to markdown converter

## Example Output

```yaml
name: Cursor AI Code Editor
description: AI-powered IDE for code generation and debugging
url: https://cursor.com/install
homepage: https://cursor.com/
source: https://github.com/cursor/cursor
license: MIT
compliances:
  - SOC-2
privileges:
  files:
    read:
      - path: $HOME/.bashrc
        purpose: check for shell config
        risk: medium
    write:
      - path: $HOME/.local/bin/cursor-agent
        purpose: install binary
        risk: low
  tools:
    - name: curl
      scope: downloads package from downloads.cursor.com
      risk: low
    - name: tar
      scope: extracts downloaded archive
      risk: low
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (auto-approved) |
| 1 | Error (fetch failed, API error) |
| 2 | Needs review (low confidence or flags) |
