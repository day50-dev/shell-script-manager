# ursh

<p align="center">
  <img width="460" height="181" alt="logo" src="https://github.com/user-attachments/assets/dd34cef1-1164-4d77-a76e-3d8caf58a233" />
  <br/><strong>Permission-aware shell script execution</strong>
</p>

**ursh** generates machine-readable permission audits for shell scripts. Instead of blindly running `curl | bash`, ursh analyzes scripts and produces structured permission manifests that can be merged, aggregated, and analyzed—especially useful for understanding transitive dependencies.

The core use case: when a script has dependencies, you can run audits on each dependency and perform set operations (intersection, union, difference) to understand what permissions are actually needed.

## Quick Start

```bash
# Audit a script - outputs JSON permission manifest
ursh audit gh:user/repo/script.sh

# Run with manifest (if one exists alongside the script)
ursh gh:user/repo/script.sh

# Merge audits from multiple scripts
ursh audit dep-a.sh > a.json
ursh audit dep-b.sh > b.json
ursh merge a.json b.json

# Find common permissions across dependencies
ursh intersect dep-audit.json dep-b.json dep-c.json

# See what script-b needs that script-a already has
ursh diff --what-new dep-audit.json dep-baudit.json
```

## Installation

```bash
curl -sSL day50.dev/ursh | bash
```

## Core Concepts

### Permission Audits

Each `ursh audit` generates a JSON manifest describing exactly what the script needs:

```json
{
  "name": "my-setup",
  "url": "https://example.com/setup.sh",
  "checksum": "sha256:abc123...",
  "permissions": {
    "files": {
      "read": [
        {"path": "/etc/hosts", "line": 15, "command": "cat /etc/hosts"}
      ],
      "write": [
        {"path": "/tmp/ursh-*", "line": 23, "command": "echo $PID > /tmp/ursh-$PID"}
      ]
    },
    "network": {
      "get": ["https://api.example.com/*"],
      "put": []
    },
    "tools": [
      {"command": "curl", "line": 10},
      {"command": "jq", "line": 12}
    ]
  }
}
```

### Mergeable & Aggregatable

Audits are designed for set operations:

```bash
# Union: everything needed by either script
ursh union audit-a.json audit-b.json

# Intersection: permissions needed by ALL scripts
ursh intersect audit-a.json audit-b.json audit-c.json

# Difference: what's needed by A but not by B
ursh diff audit-a.json audit-b.json

# Reduce: merge an entire directory of audits
ursh reduce ./audits/ --output combined.json
```

This is especially valuable for:
- **Dependency analysis**: See exactly what permissions a script chain requires
- **Least privilege enforcement**: Start with union, reduce to intersection for shared deps
- **Audit trails**: Track permission changes across versions

## Usage

### Auditing Scripts

```bash
# Audit from GitHub shorthand
ursh audit gh:user/repo/setup.sh

# Audit from URL
ursh audit https://example.com/install.sh

# Audit local script
ursh audit ./local-script.sh

# Output format (default: JSON, also supports YAML)
ursh audit --format yaml gh:user/repo/script.sh

# Verbose output (show which line triggered each permission)
ursh audit -v gh:user/repo/script.sh
```

### Running Scripts

```bash
# Standard run (will prompt if manifest exists)
ursh gh:user/repo/script.sh

# Skip permission checks (trust the script)
ursh --no-policy gh:user/repo/script.sh

# Dry-run mode
ursh --dry-run gh:user/repo/script.sh

# With arguments
ursh gh:user/repo/deploy.sh --env production
```

### Set Operations

```bash
# Merge two audits
ursh merge audit-a.json audit-b.json -o combined.json

# Find common permissions (intersection)
ursh intersect dep-a.json dep-b.json

# See what's unique to each
ursh diff dep-a.json dep-b.json

# Analyze a dependency chain
cat deps.txt | xargs -I{} ursh audit {} | ursh reduce | ursh intersect - > shared-perms.json
```

### Working with Dependencies

```bash
# Generate audits for all dependencies
for dep in $DEPS; do
  ursh audit $dep > "audits/$(basename $dep).json"
done

# What's the minimal permission set for all deps?
ursh reduce audits/*.json | ursh intersect - shared.json

# What new permissions does this version need?
ursh diff audits/old.json audits/new.json
```

## Manifest Format

The audit output is a structured JSON (or YAML) document:

```json
{
  "name": "script-name",
  "url": "https://...",
  "version": "1.0.0",
  "checksum": "sha256:...",
  "date": "2026-04-24T10:00:00Z",
  "permissions": {
    "files": {
      "read": [
        {"path": "/etc/resolv.conf", "line": 5, "command": "cat /etc/resolv.conf"}
      ],
      "write": [
        {"path": "/var/log/app.log", "line": 12, "command": ">> /var/log/app.log"}
      ]
    },
    "network": {
      "get": ["https://api.github.com/*", "https://releases.example.com/*"],
      "put": ["https://telemetry.example.com/events"]
    },
    "tools": [
      {"command": "curl", "line": 8, "type": "external"},
      {"command": "jq", "line": 15, "type": "external"}
    ],
    "dynamic": [
      {"what": "env-var:AUTH_TOKEN", "how": "reads", "source": "line 20"}
    ]
  }
}
```

## Examples

### CI/CD Security Review

```bash
# Before deploying, audit the entire chain
ursh audit gh:org/ci/setup.sh > ci-setup.json
ursh audit gh:org/ci/deploy.sh > ci-deploy.json
ursh audit gh:org/ci/test.sh > ci-test.json

# What's the total permission surface?
ursh union ci-*.json > ci-permissions.json

# What's needed by ALL stages (intersection)?
ursh intersect ci-*.json > shared-permissions.json
```

### Dependency Auditing

```bash
# Audit each dependency
ursh audit gh:kelseyhightower/nvidia-device-plugin.sh > nvidia.json
ursh audit gh:helm/helm.sh > helm.json
ursh audit gh:kubectl/kubectl.sh > kubectl.json

# Combined: all permissions needed
ursh reduce ./charts/audits/ -o chart-permissions.json

# Minimal: only shared permissions (if running all)
ursh intersect ./charts/audits/*.json -o shared-permissions.json
```

### Policy Generation

```bash
# Generate a least-privilege policy from audits
ursh audit gh:user/repo/script.sh | ursh generate-policy > policy.yaml

# Apply policy to future runs
ursh --policy policy.yaml gh:user/repo/script.sh
```

## Why ursh?

- **Transparency**: See exactly what every script will do before running
- **Composable**: Merge audits from multiple sources with set operations
- **Dependency-aware**: Understand transitive permission requirements
- **Portable**: Works on Linux, macOS, BSD

## How It Works

1. `ursh audit` analyzes the script (static analysis + sandbox hints)
2. Outputs structured permission manifest (JSON/YAML)
3. When running, ursh compares the script's behavior against the manifest
4. Prompts for confirmation, verifies checksums, executes

## Cache & Config

| Platform | Cache | Config |
|----------|-------|--------|
| Linux | `~/.cache/ursh` | `~/.config/ursh` |
| macOS | `~/Library/Caches/ursh` | `~/.config/ursh` |
| BSD | `~/.cache/ursh` | `~/.config/ursh` |

Override with `URSH_CACHE` and `XDG_CONFIG_HOME` environment variables.

## FAQ

**Q: How is this different from guardrails/sandboxing tools?**  
A: ursh is about *description and audit*, not enforcement. It tells you what a script will do, generates portable permission manifests, and enables set operations on those manifests. Guards (chroot, docker) are optional isolation, not the primary feature.

**Q: Can I trust the audits?**  
A: Audits are based on static analysis. For higher confidence, run scripts in a sandbox while auditing to capture dynamic behavior. The `confidence` field in audits reflects analysis quality.

**Q: How do set operations work?**  
A: File paths are normalized and matched by glob. Network URLs are matched by host pattern. Tools are matched by command name. Intersection finds what appears in all inputs; union finds everything.

## Installation

```bash
curl -sSL day50.dev/ursh | bash
```

Or build from source:

```bash
git clone https://github.com/day50-dev/ursh
cd ursh/cli/cmd/ursh
go build -o ursh
```