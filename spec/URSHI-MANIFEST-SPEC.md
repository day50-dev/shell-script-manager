# URSHI Manifest Specification

**Version:** 1.0.0  
**Last Updated:** 2026-01-25  
**Status:** Stable

## Table of Contents

1. [Overview](#overview)
2. [Core Fields](#core-fields)
3. [Documentation Fields](#documentation-fields)
4. [Integrity & Verification](#integrity--verification)
5. [Compliance & Certification](#compliance--certification)
6. [Privileges & Permissions](#privileges--permissions)
7. [Optional Metadata](#optional-metadata)
8. [Examples](#examples)
9. [Validation](#validation)
10. [Best Practices](#best-practices)

---

## Overview

A **URSHI** (Universal Remote Shell Script Hosting Interface) manifest is a metadata specification for remote shell scripts that enables safe execution by declaring intentions, privileges, and compliance information. It serves as a replacement for `curl <url> | bash` patterns by providing structured metadata for human, LLM, and classical tool ingestion.

### Purpose

- **Trust Assessment:** Enable users and automated systems to evaluate script trustworthiness
- **Privilege Declaration:** Explicitly declare what resources a script needs to access
- **Compliance Tracking:** Document regulatory compliance certifications
- **Integrity Verification:** Provide checksums for script verification
- **Discovery:** Enable search and categorization of scripts

### Format Support

The canonical format is **YAML**, but urshi manifests can be serialized as:
- YAML (`.urshi.yaml` or `.urshi.yml`)
- JSON (`.urshi.json`)
- TOML (`.urshi.toml`)

---

## Core Fields

### `name` (Required)

**Type:** `string`  
**Pattern:** `^[a-zA-Z0-9][a-zA-Z0-9_-]*$`  
**Length:** 1-255 characters

The unique identifier for the tool/script. Should be lowercase with hyphens or underscores as separators.

```yaml
name: hello-world
name: docker-dev-setup
name: healthcare-backup
```

### `description` (Required)

**Type:** `string`  
**Length:** 1-2048 characters

A clear, concise description of what the tool/script does. Should be understandable by both humans and automated systems.

```yaml
description: A simple hello world script for testing ursh functionality
description: Sets up Docker containers for a complete development environment
```

### `url` (Required)

**Type:** `string` (URI)  
**Format:** Valid URL

The primary location where the script resides. **This is the primary source of trust assessment.** Domains and paths are analyzed for reputation:

- `github.com/microsoft` → High trust (established organization)
- `github.com/randomuser123` → Medium trust (individual)
- `shady-domain.ru` → Low trust (unknown/suspicious)

```yaml
url: https://github.com/microsoft/dev-tools/blob/main/scripts/docker-setup.sh
url: https://raw.githubusercontent.com/user/repo/main/script.sh
```

### `homepage` (Optional)

**Type:** `string` (URI)  
**Format:** Valid URL

A URL for more information about the tool, such as a project repository, documentation site, or landing page.

```yaml
homepage: https://github.com/microsoft/dev-tools
homepage: https://example.com/project-docs
```

> **Note:** If `url` and `homepage` share the same domain, they should have matching author/organization paths. Mismatches are flagged for manual review.

---

## Documentation Fields

### `readme` (Optional)

**Type:** `string`  
**Default:** `""`

README content or a URL to the README. Can be blank if not available. Should contain:
- Usage instructions
- Examples
- Requirements
- Additional context

```yaml
# Inline README
readme: |
  # Hello World Example

  This is a minimal example script that prints "Hello, World!" to stdout.

  ## Usage
  ```bash
  ursh run hello-world
  ```

# URL to README
readme: https://github.com/microsoft/dev-tools/blob/main/README.md

# Blank (not provided)
readme: ""
```

### `license` (Optional)

**Type:** `string`  
**Default:** `""`

License identifier or URL to the license. Recommended to use [SPDX license identifiers](https://spdx.org/licenses/) when possible.

```yaml
license: MIT
license: Apache-2.0
license: GPL-3.0-only
license: "Custom - See https://example.com/license"
license: ""  # Not specified
```

---

## Integrity & Verification

### `checksum` (Required)

**Type:** `string`  
**Pattern:** `^(sha256|sha512|md5):[a-fA-F0-9]+$`

The last known checksum of the script for integrity verification. **SHA-256 or stronger is recommended.**

```yaml
checksum: "sha256:a3f2b8c9d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1"
checksum: "sha512:c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6..."
```

### `date` (Required)

**Type:** `string`  
**Format:** ISO 8601 date-time

The ISO 8601 formatted date of the last check/verification of the script.

```yaml
date: "2024-01-15T10:30:00Z"
date: "2024-01-15T10:30:00+00:00"
date: "2024-01-15T10:30:00-05:00"
```

---

## Compliance & Certification

### `compliances` (Optional)

**Type:** `array[string]`  
**Default:** `[]`

List of certifications the source page attests to. Empty array if no certifications apply.

### Supported Certifications

| Certification | Description |
|--------------|-------------|
| `HIPAA` | Health Insurance Portability and Accountability Act |
| `SOC-2` | Service Organization Control 2 |
| `SOC-2-Type-2` | SOC 2 Type II (extended audit period) |
| `ISO-27001` | Information Security Management |
| `GDPR` | General Data Protection Regulation (EU) |
| `PCI-DSS` | Payment Card Industry Data Security Standard |
| `FedRAMP` | Federal Risk and Authorization Management Program |
| `HITRUST` | Health Information Trust Alliance |
| `CCPA` | California Consumer Privacy Act |
| `FISMA` | Federal Information Security Management Act |
| `NIST-800-53` | NIST Security Controls |
| `CSA-STAR` | Cloud Security Alliance Security Trust Assurance |
| `IRAP` | Information Security Registered Assessors Program (Australia) |
| `MTCS` | Multi-Tier Cloud Security (Singapore) |
| `ENS` | Esquema Nacional de Seguridad (Spain) |
| `C5` | Cloud Computing Compliance Criteria Catalogue (Germany) |
| `HDS` | Hebergement Donnees de Sante (France) |
| `Custom` | Custom certification (describe in documentation) |

```yaml
# No certifications
compliances: []

# Multiple certifications
compliances:
  - HIPAA
  - SOC-2
  - ISO-27001

# Single certification
compliances:
  - GDPR
```

---

## Privileges & Permissions

The `privileges` section is **required** and declares all resources the script needs to access. This follows the **principle of least privilege**.

### Structure

```yaml
privileges:
  files:
    read: [...]
    write: [...]
  network:
    get: [...]
    put: [...]
  tools:
    - name: <tool>
      scope: <scope>
  dynamic:
    - what: <description>
      how: <method>
      source: <optional-source>
```

### `privileges.files`

**Type:** `object`  
**Required:** `true`

Declares file system access requirements.

#### `privileges.files.read`

**Type:** `array[string]`  
**Default:** `[]`

List of file paths or patterns the script needs to **read**.

```yaml
files:
  read:
    - /etc/hosts
    - ~/.config/app/*
    - /tmp/*
    - /var/log/app.log
```

#### `privileges.files.write`

**Type:** `array[string]`  
**Default:** `[]`

List of file paths or patterns the script needs to **write**.

```yaml
files:
  write:
    - /tmp/output.txt
    - ~/.local/bin/*
    - /var/log/app/*.log
```

### `privileges.network`

**Type:** `object`  
**Required:** `true`

Declares network resource access requirements.

#### `privileges.network.get`

**Type:** `array[string]` (URI)  
**Default:** `[]`

URLs the script pulls data from (read-only operations).

```yaml
network:
  get:
    - https://api.example.com/data
    - https://cdn.example.com/assets/*
    - https://raw.githubusercontent.com/user/repo/main/*
```

#### `privileges.network.put`

**Type:** `array[string]` (URI)  
**Default:** `[]`

URLs the script sends data to. **Important:** This includes URLs where query parameters are constructed from file contents or computations, even if using HTTP GET method.

```yaml
# Direct PUT/POST endpoints
network:
  put:
    - https://api.example.com/submit
    - https://analytics.example.com/track

# Computed GET requests (data sent via query parameters)
network:
  put:
    - https://somesite.com/query?*    # Query built from file contents
    - https://api.example.com/search?q=*
```

> **Example:** `curl "somesite.com?q=$(cat /etc/hostname)"` is a **PUT** operation because it sends local data to a remote server.

### `privileges.tools`

**Type:** `array[object]`  
**Default:** `[]`

Tools/commands the script wants to use with their scope.

#### Structure

```yaml
tools:
  - name: <tool_name>
    scope: <scope_description>
```

#### Scope Values

| Scope | Description |
|-------|-------------|
| `unrestricted` | Full access to the tool |
| `restricted` | Limited access (specify in documentation) |
| `<path>` | Limited to specific path (e.g., `/tmp`) |
| `<host>:<port>` | Limited to specific network endpoint |
| `read-only` | Read-only operations only |

#### Examples

```yaml
# Single tool with unrestricted access
tools:
  - name: docker
    scope: unrestricted

# Multiple tools with various scopes
tools:
  - name: mkdir
    scope: /tmp
  - name: git
    scope: ~/projects
  - name: curl
    scope: restricted
  - name: echo
    scope: unrestricted

# System tools
tools:
  - name: openssl
    scope: unrestricted
  - name: aws
    scope: s3://healthcare-backups/*
  - name: gpg
    scope: unrestricted
```

### `privileges.dynamic`

**Type:** `array[object]`  
**Default:** `[]`

Anything constructed programmatically, such as through generative AI, templates, or runtime computation. **All dynamic content generation MUST be disclosed here.**

#### Structure

```yaml
dynamic:
  - what: <what_is_generated>
    how: <generation_method>
    source: <optional_source_url>
```

#### Examples

```yaml
# Environment variable interpolation
dynamic:
  - what: Configuration values
    how: Environment variable interpolation

# Generative AI
dynamic:
  - what: Generated code content
    how: Generative AI (LLM) - OpenAI GPT-4
    source: https://api.openai.com/v1/chat/completions

# Template engine
dynamic:
  - what: Docker compose configuration
    how: Template engine with environment variable interpolation
    source: Environment variables and .env.example

# Runtime computation
dynamic:
  - what: Backup file naming
    how: Timestamp and checksum interpolation

# Multiple dynamic elements
dynamic:
  - what: AI prompt construction
    how: Template engine with user input and project context
    source: project-spec.md and templates
  - what: Generated code content
    how: Generative AI (LLM) - OpenAI GPT-4 or Anthropic Claude
    source: https://api.openai.com/v1/chat/completions
  - what: Output file paths
    how: Computed from project structure and naming conventions
```

---

## Optional Metadata

### `version`

**Type:** `string`  
**Pattern:** `^\d+\.\d+\.\d+$`

Version of the urshi manifest or script version (Semantic Versioning recommended).

```yaml
version: "1.0.0"
version: "2.1.0"
version: "0.1.0"
```

### `author`

**Type:** `object`

Author information for the script.

```yaml
author:
  name: Microsoft Dev Tools Team
  email: devtools@microsoft.com
  url: https://github.com/microsoft/dev-tools
```

### `tags`

**Type:** `array[string]`

Tags for categorization and discovery.

```yaml
tags:
  - docker
  - development
  - setup
  - containers
```

### `dependencies`

**Type:** `array[object]`

Other urshis or tools this script depends on.

```yaml
dependencies:
  - name: docker
    version: ">=20.10.0"
  - name: docker-compose
    version: ">=2.0.0"
  - name: openssl
    version: ">=1.1.1"
```

### `environment`

**Type:** `object`

Environment variables required by the script. Values indicate requirement status.

```yaml
environment:
  API_KEY: required
  DEBUG_MODE: optional
  LOG_LEVEL: optional
  DATABASE_URL: required
```

---

## Examples

Complete examples can be found in the [`examples/`](./examples/) directory:

1. **[example-01-hello-world.urshi.yaml](./examples/example-01-hello-world.urshi.yaml)** - Minimal hello world script
2. **[example-02-docker-setup.urshi.yaml](./examples/example-02-docker-setup.urshi.yaml)** - Docker development environment
3. **[example-03-healthcare-backup.urshi.yaml](./examples/example-03-healthcare-backup.urshi.yaml)** - HIPAA-compliant backup script
4. **[example-04-ai-codegen.urshi.yaml](./examples/example-04-ai-codegen.urshi.yaml)** - AI-powered code generator
5. **[example-05-minimal-privileges.urshi.yaml](./examples/example-05-minimal-privileges.urshi.yaml)** - Read-only system info script

---

## Validation

### JSON Schema

A JSON Schema is provided for validation: [`urshi-manifest.schema.json`](./urshi-manifest.schema.json)

### YAML Schema

A YAML Schema definition is provided: [`urshi-manifest.schema.yaml`](./urshi-manifest.schema.yaml)

### Validation Tools

```bash
# Validate with Python (using jsonschema)
pip install jsonschema
python -c "import json, jsonschema; schema=json.load(open('urshi-manifest.schema.json')); manifest=json.load(open('manifest.urshi.json')); jsonschema.validate(manifest, schema)"

# Validate with Node.js (using ajv)
npm install -g ajv-cli
ajv validate -s urshi-manifest.schema.json -d manifest.urshi.json
```

---

## Best Practices

### 1. Principle of Least Privilege

Always declare the minimum privileges necessary:

```yaml
# Bad: Overly permissive
tools:
  - name: mkdir
    scope: unrestricted

# Good: Restricted to specific path
tools:
  - name: mkdir
    scope: /tmp
```

### 2. Be Specific with Paths

Use specific paths instead of wildcards when possible:

```yaml
# Bad: Too broad
files:
  read:
    - /*

# Good: Specific paths
files:
  read:
    - /etc/hosts
    - /proc/version
```

### 3. Disclose All Dynamic Content

Always disclose dynamic content generation:

```yaml
# Bad: Hidden dynamic behavior
dynamic: []

# Good: Fully disclosed
dynamic:
  - what: API endpoint URLs
    how: Environment variable interpolation
```

### 4. Use Secure Checksums

Always use SHA-256 or stronger:

```yaml
# Bad: Weak hash
checksum: "md5:abc123..."

# Good: Strong hash
checksum: "sha256:a3f2b8c9..."
```

### 5. Keep Dates Current

Regularly update the `date` field when verifying scripts:

```yaml
# Update this when re-verifying the script
date: "2024-01-25T16:20:00Z"
```

### 6. Document Compliance Accurately

Only claim certifications that actually apply:

```yaml
# Bad: Claiming unverified certifications
compliances:
  - HIPAA
  - SOC-2

# Good: Only verified certifications
compliances:
  - SOC-2
```

### 7. Provide Complete Author Information

Help users identify the source:

```yaml
# Good: Complete author info
author:
  name: Security Team
  email: security@example.com
  url: https://github.com/example/security-tools
```

---

## Security Considerations

### Domain Reputation

The `url` field is the primary trust indicator. Automated systems should:

1. Check domain reputation scores
2. Verify URL and homepage domain alignment
3. Flag mismatched author paths for review
4. Consider organization verification status

### Privilege Escalation

Watch for privilege escalation patterns:

- Scripts requesting `unrestricted` tool access
- Write access to sensitive directories (`/etc`, `/usr`, etc.)
- Network access to unknown/suspicious domains
- Undisclosed dynamic content generation

### Dynamic Content Risks

Dynamic content (especially AI-generated) introduces additional risks:

- Prompt injection vulnerabilities
- Data leakage through API calls
- Unpredictable behavior
- Compliance implications

Always review `privileges.dynamic` carefully.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01-25 | Initial stable release |

---

## Contributing

To propose changes to this specification:

1. Open an issue on the ursh repository
2. Submit a pull request with proposed changes
3. Include example manifests demonstrating the changes

---

## License

This specification is licensed under the same terms as the ursh project. See [LICENSE](../../LICENSE.MIT) for details.
