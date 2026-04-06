# ursh.dev - Next Generation

This directory contains the next generation of ursh.dev tooling and infrastructure.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `spec/` | Urshi manifest specification and schema |
| `tooling/` | Python tooling to analyze scripts and generate manifests |
| `website/` | Full-stack web application for urshi registry |
| `review/` | Review flagging system for domain/author mismatch detection |
| `urshin/` | Standalone CLI tool for manifest generation |
| `infer/` | (Deprecated - merged into urshin) |

## Quick Start

### Generate a manifest from a script URL
```bash
cd urshin
direnv allow
urshin create gh:user/repo/script.sh
```

### Run the website
```bash
cd website
./start.sh
```

## Architecture

```
ursh.dev
├── spec/          # YAML/JSON schema definitions
├── tooling/       # Script analysis library
├── website/       # React + Node.js registry UI
├── review/        # Mismatch detection system
└── urshin/        # Standalone CLI (recommended)
```

The **urshin** CLI is the primary tool for generating urshi manifests. It uses multi-pass sequential bootstrap inference to:
1. Find the project homepage
2. Locate README/documentation
3. Infer a descriptive name
4. Find source repository
5. Detect license
6. Identify compliance certifications
7. Analyze script privileges with surface area scopes
