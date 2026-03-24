# URSHI Policy Specification

**Version:** 1.0.0  
**Last Updated:** 2025-01-20  
**Status:** Stable

## Table of Contents

1. [Overview](#overview)
2. [Policy File Format](#policy-file-format)
3. [Policy Structure](#policy-structure)
4. [Decision Types](#decision-types)
5. [Scope Matching](#scope-matching)
6. [Pattern Matching](#pattern-matching)
7. [Policy Evaluation](#policy-evaluation)
8. [Policy Directory](#policy-directory)
9. [Runtime Behavior](#runtime-behavior)
10. [Examples](#examples)
11. [Best Practices](#best-practices)

---

## Overview

**Policies** are scoped, purpose-driven rules that determine how ursh handles script actions. When a script attempts to access files, network resources, or use tools, policies define whether the action should be:

- **Allowed** - Action permitted without prompting
- **Denied** - Action blocked
- **Asked** - User prompted for decision

### Default Behavior

The **default behavior is Ask** - if no policy matches an action, the user is prompted to decide. This ensures users always have control over unknown actions.

### Policy-Driven Security

Unlike traditional execution models that rely solely on manifest declarations, policies provide:

1. **User Control** - Override default Allow/Deny decisions
2. **Persistent Rules** - Remember decisions across sessions
3. **Pattern-Based Matching** - Use glob patterns for flexible matching
4. **Scope-Based Application** - Apply policies to specific tools, paths, or purposes

---

## Policy File Format

Policies are stored as **YAML files** in the policy directory (`~/.config/ursh/policies/` by default).

### Filename Convention

Policies use **SYS-V style rc.d numbering** for ordering:

```
<priority>-<name>.yaml
```

Where:
- `<priority>` is a two-digit number (00-99)
- `<name>` is a lowercase, hyphenated name
- Lower numbers load first, allowing overrides

```yaml
# Examples
10-system-defaults.yaml    # Built-in defaults
50-user-custom.yaml        # User policies
99-override.yaml           # High-priority overrides
```

### YAML Schema

```yaml
name: <string>              # Required: Policy identifier
description: <string>       # Optional: Human-readable description
scope:                      # Optional: When this policy applies
  inclusions:               # Paths/purposes this policy covers
    path: []                # Path patterns to match
    purpose: []             # Purpose patterns to match
  ask:                      # Scope that triggers asking
    path: []
    purpose: []
  exclusions:               # Paths/purposes to exclude
    path: []
    purpose: []
compliances:                # Optional: Compliance requirements
  inclusions: []            # Required compliances
  ask: []                   # Ask about these
  exclusions: []            # Forbidden compliances
licenses:                   # Optional: License requirements
  inclusions: []
  ask: []
  exclusions: []
privileges:                 # Required: Action rules
  files:                    # File access rules
    inclusions: []          # Allowed paths
    ask: []                 # Paths that prompt
    exclusions: []          # Denied paths
  network:                  # Network access rules
    inclusions: []          # Allowed URLs/domains
    ask: []                 # URLs that prompt
    exclusions: []          # Denied URLs/domains
  tools:                    # Tool usage rules
    inclusions: []          # Allowed tools
    ask: []                 # Tools that prompt
    exclusions: []          # Denied tools
  dynamic:                  # Dynamic content rules (requires inference)
    inclusions: []          # Allowed descriptions
    ask: []                 # Descriptions that prompt
    exclusions: []          # Forbidden descriptions
```

---

## Policy Structure

### `name` (Required)

**Type:** `string`  
**Pattern:** `^[a-z0-9][a-z0-9_-]*$`

Unique identifier for the policy.

```yaml
name: crypto-trading-bot
name: development-tools
name: system-maintenance
```

### `description` (Optional)

**Type:** `string`

Human-readable description of what this policy covers.

```yaml
description: Policy for cryptocurrency trading automation bots
description: Development environment setup tools
```

### `scope` (Optional)

Defines when this policy should be considered. Uses **purpose matching** against the urshi manifest's description field.

```yaml
scope:
  inclusions:
    purpose:
      - "installs"
      - "setup"
    path:
      - "/usr/local/*"
  exclusions:
    purpose:
      - "test"
```

### `privileges` (Required)

The core policy rules defining Allow/Deny/Ask behavior for actions.

```yaml
privileges:
  files:
    inclusions:
      - "/tmp/*"
      - "/var/tmp/*"
    exclusions:
      - "/home/*/.ssh/*"
      - "/home/*/.aws/*"
    ask:
      - "/etc/*"
  network:
    inclusions:
      - "github.com/*"
      - "api.github.com/*"
    exclusions:
      - "*.onion/*"
    ask:
      - "*"
```

---

## Decision Types

### Allow

Actions matching inclusions are **permitted automatically** without prompting.

```yaml
privileges:
  files:
    inclusions:
      - "/tmp/*"        # Can read/write /tmp without asking
  network:
    inclusions:
      - "github.com/*" # Can access GitHub without asking
```

### Deny

Actions matching exclusions are **blocked** and execution stops.

```yaml
privileges:
  files:
    exclusions:
      - "/home/*/.ssh/*"  # Cannot access SSH keys
      - "/etc/shadow"     # Cannot read shadow file
  network:
    exclusions:
      - "*.onion/*"       # Cannot access Tor hidden services
```

### Ask

Actions matching ask patterns **prompt the user** for a decision.

```yaml
privileges:
  files:
    ask:
      - "/etc/*"        # Prompt for /etc access
  network:
    ask:
      - "*"             # Prompt for any network access
```

### Default (No Match)

**When no policy matches an action, the default is Ask.** This ensures users always have control over unknown actions.

---

## Scope Matching

Policies can be scoped to specific tools, paths, or purposes using the `scope` field.

### Purpose Matching

Matches against the urshi manifest's `description` field using glob patterns:

```yaml
scope:
  inclusions:
    purpose:
      - "installs"      # Matches descriptions containing "installs"
      - "docker*"       # Matches "docker-setup", "docker-build", etc.
      - "*backup*"      # Matches "backup", "mysql-backup", etc.
```

### Path Matching

Matches against the script's origin or installation path:

```yaml
scope:
  inclusions:
    path:
      - "/usr/local/bin/*"
      - "~/.local/bin/*"
```

### Exclusion Scope

Exclude certain cases from a broader policy:

```yaml
scope:
  inclusions:
    purpose:
      - "installs"
  exclusions:
    purpose:
      - "test"
```

---

## Pattern Matching

Policies use **glob patterns** for flexible matching:

| Pattern | Matches | Does Not Match |
|---------|---------|----------------|
| `*` | Anything | - |
| `/tmp/*` | `/tmp/file`, `/tmp/subdir/file` | `/var/tmp/file` |
| `/home/*/.ssh/*` | `/home/user/.ssh/id_rsa` | `/home/user/.aws/credentials` |
| `github.com/*` | `github.com/user/repo`, `api.github.com/user` | `gitlab.com/user` |
| `*.onion/*` | `example.onion/site` | `example.com/site` |
| `/etc/*.conf` | `/etc/nginx.conf` | `/etc/default/nginx` |

### Pattern Escaping

Literal asterisks can be matched by escaping:

```yaml
# Match literal file named "test*"
- "test\\*"
```

---

## Policy Evaluation

### Evaluation Order

1. **Load Policies** - Read all `.yaml` files from policy directory, sorted by priority (lowest first)
2. **Analyze Script** - Scan script for potential actions (file, network, tool usage)
3. **Match Each Action** - For each action, find first matching policy with non-Ask decision
4. **Apply Decision** - Allow, Deny, or Ask based on matched policy

### Decision Flow

```
Action Detected
      │
      ▼
┌─────────────────┐
│ Find Matching   │
│ Policy          │
└────────┬────────┘
         │
         ▼
   ┌───────────┐
   │ Decision? │
   └─────┬─────┘
         │
    ┌────┴────┐
    │         │
 Allow    ┌───┴────┐
    │     Deny    Ask
    │     │      │
    ▼     ▼      ▼
Execute  Block  Prompt User
```

### First-Match Wins

When multiple policies could match an action, the **first policy with a non-Ask decision wins**:

```yaml
# Policy 10-defaults.yaml (loaded first)
privileges:
  files:
    ask:
      - "*"   # Ask about ALL file access

# Policy 50-tmp-only.yaml (loaded second)
privileges:
  files:
    inclusions:
      - "/tmp/*"  # But allow /tmp
```

Result: Access to `/tmp/*` is **Allowed** because the second policy matches first.

---

## Policy Directory

### Default Location

```
~/.config/ursh/policies/
```

### Environment Override

```bash
export URSH_CONFIG=~/my-config
# Policies would be at: ~/my-config/policies/
```

### Directory Structure

```
~/.config/ursh/
└── policies/
    ├── 10-system.yaml      # System defaults
    ├── 20-network-tools.yaml
    ├── 50-user-defaults.yaml
    └── 99-override.yaml   # User overrides
```

---

## Runtime Behavior

### Interactive Prompt

When an unknown action is detected, the user is prompted:

```
⚠️  Policy Check: Script wants to file: /etc/passwd
  [A]llow  [D]eny  [a]sk always  [N]ever ask  [V]iew  [E]dit and save new policy
  Choice: _
```

### Prompt Options

| Option | Short | Behavior |
|--------|-------|----------|
| Allow | a | Allow this action once |
| Deny | d | Deny this action, stop execution |
| Ask | ask | Always ask for this type |
| Never | n | Add to exclusions (deny always) |
| View | v | Show script/policy context |
| Edit | e | Open $EDITOR to create new policy |

### Policy Creation

When choosing **Edit**, a template policy is created:

```yaml
name: new-script-policy
privileges:
  files:
    inclusions: []
    exclusions: []
    ask:
      - "/etc/passwd"
  network:
    inclusions: []
    exclusions: []
    ask: []
  tools:
    inclusions: []
    exclusions: []
    ask: []
```

The user can edit this template and save it to the policy directory.

### Bypass Options

Users can skip policy enforcement:

```bash
ursh --no-policy gh:user/repo/script.sh  # Skip all policy checks
```

---

## Examples

### Example 1: Development Tools

```yaml
# 50-dev-tools.yaml
name: development-tools
description: Policy for development and build tools

scope:
  inclusions:
    purpose:
      - "development"
      - "build"

privileges:
  files:
    inclusions:
      - "/tmp/*"
      - "~/projects/*"
      - "~/workspace/*"
    exclusions:
      - "~/projects/*/secrets/*"
    ask:
      - "/etc/*"
      - "/var/*"

  network:
    inclusions:
      - "github.com/*"
      - "gitlab.com/*"
      - "npmjs.org/*"
      - "pypi.org/*"
    ask:
      - "*"

  tools:
    inclusions:
      - "git"
      - "npm"
      - "yarn"
      - "pip"
      - "docker"
```

### Example 2: Crypto Trading Bot

```yaml
# 50-crypto-bot.yaml
name: crypto-trading-bot
description: Allow crypto operations, block sensitive file access

scope:
  inclusions:
    purpose:
      - "crypto"
      - "trading"
      - "exchange"

privileges:
  files:
    inclusions:
      - "/tmp/*"
      - "~/crypto-data/*"
      - "~/logs/crypto/*"
    exclusions:
      - "/home/*/.ssh/*"
      - "/home/*/.aws/*"
      - "/home/*/.kube/*"
    ask:
      - "/etc/*"

  network:
    inclusions:
      - "*.binance.com/*"
      - "*.coinbase.com/*"
      - "*.kraken.com/*"
      - "api.coingecko.com/*"
    exclusions:
      - "*.onion/*"
      - "*.i2p/*"
```

### Example 3: Minimal Privilege

```yaml
# 10-minimal.yaml
name: minimal-privileges
description: Only allow /tmp and localhost network

privileges:
  files:
    inclusions:
      - "/tmp/*"
      - "/var/tmp/*"
    ask:
      - "*"

  network:
    inclusions:
      - "localhost"
      - "127.0.0.1"
    ask:
      - "*"
```

### Example 4: Game/Entertainment

```yaml
# 50-games.yaml
name: games-policy
description: Allow game scripts limited file/network access

scope:
  inclusions:
    purpose:
      - "game"
      - "fun"
      - "entertainment"

privileges:
  files:
    inclusions:
      - "/tmp/*"
    exclusions:
      - "/home/*/.ssh/*"
      - "/home/*/.aws/*"
      - "/etc/*"
    ask:
      - "*"

  network:
    inclusions:
      - "localhost"
    exclusions:
      - "*"
    ask:
      - "*"
```

---

## Best Practices

### 1. Use Purpose-Based Scoping

Match policies to script purposes for granular control:

```yaml
scope:
  inclusions:
    purpose:
      - "installs"
      - "setup"
```

### 2. Follow Principle of Least Privilege

Start restrictive, expand as needed:

```yaml
# Start with: Ask for everything
privileges:
  files:
    ask:
      - "*"

# Expand to: Allow /tmp only
privileges:
  files:
    inclusions:
      - "/tmp/*"
    ask:
      - "*"
```

### 3. Use Priority Ordering

Organize policies by priority:

- **00-09**: System defaults (deny sensitive paths)
- **10-49**: Built-in policies
- **50-89**: User policies
- **90-99**: High-priority overrides

### 4. Document Policy Rationale

Add descriptions explaining why decisions were made:

```yaml
description: Allow file access to /tmp for temporary operations
description: Block SSH keys to prevent credential exfiltration
```

### 5. Test Policies

Use `--dry-run` to preview policy behavior:

```bash
ursh -n gh:user/repo/script.sh
```

### 6. Review Policy Decisions

Periodically review saved policies for:

- Outdated rules
- Overly permissive allowances
- Unnecessary denies

---

## Security Considerations

### Credential Protection

Always exclude credential paths:

```yaml
files:
  exclusions:
    - "/home/*/.ssh/*"
    - "/home/*/.aws/*"
    - "/home/*/.kube/*"
    - "/home/*/.gnupg/*"
```

### Network Restrictions

Be explicit about allowed network destinations:

```yaml
network:
  inclusions:
    - "github.com/*"      # Explicit domains
    - "api.example.com/*"
  exclusions:
    - "*.onion/*"         # Block Tor
```

### Tool Restrictions

Limit dangerous tools:

```yaml
tools:
  exclusions:
    - "curl"              # Block when possible
    - "wget"              # Use built-in mechanisms instead
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-01-20 | Initial policy specification |

---

## Related Documents

- [URSHI Manifest Spec](./URSHI-MANIFEST-SPEC.md) - URSHI manifest format
- [format.md](../format.md) - Original policy format reference

---

## License

This specification is licensed under the same terms as the ursh project. See [LICENSE](../../LICENSE.MIT) for details.