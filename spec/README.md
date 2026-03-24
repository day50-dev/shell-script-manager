# URSHI Specification

This directory contains the formal specification for URSHI (Universal Remote Shell Script Hosting Interface) manifests.

## Contents

### Schema Definitions

| File | Description |
|------|-------------|
| [`urshi-manifest.schema.yaml`](./urshi-manifest.schema.yaml) | YAML Schema definition with full type annotations and validation rules |
| [`urshi-manifest.schema.json`](./urshi-manifest.schema.json) | JSON Schema for programmatic validation |

### Documentation

| File | Description |
|------|-------------|
| [`URSHI-MANIFEST-SPEC.md`](./URSHI-MANIFEST-SPEC.md) | Complete specification documentation with field descriptions, examples, and best practices |

### Examples

The [`examples/`](./examples/) directory contains valid urshi manifest examples:

| File | Description |
|------|-------------|
| [`example-01-hello-world.urshi.yaml`](./examples/example-01-hello-world.urshi.yaml) | Minimal hello world script with no file/network access |
| [`example-02-docker-setup.urshi.yaml`](./examples/example-02-docker-setup.urshi.yaml) | Docker development environment setup with moderate privileges |
| [`example-03-healthcare-backup.urshi.yaml`](./examples/example-03-healthcare-backup.urshi.yaml) | HIPAA-compliant healthcare backup script with strict compliance requirements |
| [`example-04-ai-codegen.urshi.yaml`](./examples/example-04-ai-codegen.urshi.yaml) | AI-powered code generator with dynamic content generation |
| [`example-05-minimal-privileges.urshi.yaml`](./examples/example-05-minimal-privileges.urshi.yaml) | Read-only system info script demonstrating minimal privileges |

## Quick Start

### Creating a URSHI Manifest

```yaml
name: my-script
description: What my script does
url: https://github.com/user/repo/blob/main/script.sh
homepage: https://github.com/user/repo
checksum: "sha256:abc123..."
date: "2024-01-25T10:00:00Z"
compliances: []
privileges:
  files:
    read: []
    write: []
  network:
    get: []
    put: []
  tools:
    - name: echo
      scope: unrestricted
  dynamic: []
```

### Validating a Manifest

Using Python:
```bash
pip install jsonschema
python -c "
import json, jsonschema
schema = json.load(open('urshi-manifest.schema.json'))
manifest = json.load(open('my-manifest.urshi.json'))
jsonschema.validate(manifest, schema)
print('Valid!')
"
```

Using Node.js:
```bash
npm install -g ajv-cli
ajv validate -s urshi-manifest.schema.json -d my-manifest.urshi.json
```

## Field Summary

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique identifier for the tool |
| `description` | string | What the tool does |
| `url` | URI | Where the script lives (trust source) |
| `checksum` | string | Integrity verification hash |
| `date` | ISO 8601 | Last verification date |
| `privileges` | object | Declared permissions |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `homepage` | URI | More information URL |
| `readme` | string | README content or URL |
| `license` | string | License identifier |
| `compliances` | array | Certifications (HIPAA, SOC-2, etc.) |
| `version` | string | Version number |
| `author` | object | Author information |
| `tags` | array | Categorization tags |
| `dependencies` | array | Tool dependencies |
| `environment` | object | Required environment variables |

### Privileges Structure

```yaml
privileges:
  files:
    read: [paths to read]
    write: [paths to write]
  network:
    get: [URLs to fetch]
    put: [URLs to send data]
  tools:
    - name: tool_name
      scope: access_scope
  dynamic:
    - what: description
      how: generation_method
      source: optional_source
```

## Specification Version

**Current Version:** 1.0.0

## Related Documents

- [Main URSHI README](../README.md) - Overview of the ursh concept
- [URSHI Manifest Spec](./URSHI-MANIFEST-SPEC.md) - Detailed specification

## Contributing

To propose changes to the specification:

1. Review the existing schema files
2. Create example manifests demonstrating your use case
3. Update the documentation
4. Submit a pull request

## License

This specification is licensed under the same terms as the ursh project. See [LICENSE](../../LICENSE.MIT) for details.
