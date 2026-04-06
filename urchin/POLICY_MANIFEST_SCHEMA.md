# Urshin Policy Manifest Schema
# 
# This document defines the schema for urshi privilege manifests.
# Use this as a reference for prompt engineering - the LLM output
# MUST conform to this schema.
#
# Key principle: Each operation is a discrete action that can be
# individually allowed/denied by policy.

# =============================================================================
# TOOLS SCHEMA (for privileges.tools)
# =============================================================================

# Each tool entry MUST have these fields:
{
  "line": 90,                    # Line number (1-indexed integer)
  "command": "rm",               # Command NAME only (single word, no args)
  "full_command": "rm -rf /tmp/foo",  # Full command line as it appears
  "resource": "/tmp/foo",        # The specific file/path/URL affected
  "type": "file_write"           # One of: file_read, file_write, network_get, network_put
}

# COMMAND FIELD RULES:
# - MUST be just the command name (e.g., "rm", "curl", "cat")
# - MUST NOT include arguments or flags
# - MUST be a single word (no spaces)

# Examples:
# GOOD:  "command": "rm"
# BAD:   "command": "rm -rf /tmp"
# GOOD:  "command": "curl"
# BAD:   "command": "curl -O https://..."
      
  # Grouped views for convenience (derived from operations)
  files:
    read:
      - path: /etc/passwd
        line: 45
        command: cat /etc/passwd
    write:
      - path: /tmp/output.txt
        line: 90
        command: rm -rf /tmp/output.txt
  network:
    get:
      - url: https://example.com/file.tar.gz
        line: 23
        command: curl -O https://example.com/file.tar.gz
    put: []
  tools: []     # Deprecated - use operations instead
  dynamic: []   # For eval, command substitution, etc. (future)

# =============================================================================
# OPERATION TYPES
# =============================================================================

# file_read: Command reads from a file path
# Examples: cat, grep, head, tail, less, more, source, .
- type: file_read
  resource: /etc/passwd           # Must start with /, ~, or $
  command: cat /etc/passwd
  line: 5

# file_write: Command writes/deletes/modifies a file path  
# Examples: rm, cp, mv, tee, chmod, chown, >, >>, truncate
- type: file_write
  resource: /tmp/file.txt
  command: rm -rf /tmp/file.txt
  line: 90

# network_get: HTTP GET request
# Examples: curl, wget
- type: network_get
  resource: https://example.com/file.tar.gz
  command: curl -O https://example.com/file.tar.gz
  line: 23

# network_put: HTTP PUT/POST request
# Examples: curl -X PUT, curl -d
- type: network_put
  resource: https://api.example.com/upload
  command: curl -X POST -d @file.txt https://api.example.com/upload
  line: 45

# =============================================================================
# RESOURCE FORMAT RULES
# =============================================================================

# Resources MUST be one of these formats:
# 
# 1. Absolute path: /etc/passwd, /tmp/file.txt
# 2. Home-relative: ~/.bashrc, ~/projects/myapp
# 3. Variable path: $HOME/.config, ${TEMP_DIR}/output
# 4. URL: https://example.com/file, http://localhost:8080/api

# INVALID resource formats (DO NOT OUTPUT):
# - "the temp directory" (not specific)
# - "user's home directory" (not specific)
# - "downloaded file" (not specific)
# - Empty string

# =============================================================================
# COMMAND FORMAT RULES
# =============================================================================

# Command MUST be the full command line as it appears in script
# Include all flags and arguments

# GOOD:
command: curl -fSL --progress-bar "${DOWNLOAD_URL}"
command: rm -rf "${TEMP_EXTRACT_DIR}"
command: mkdir -p ~/.local/bin

# BAD (too abbreviated):
command: curl
command: rm
command: mkdir

# =============================================================================
# EXAMPLE POLICY QUERIES
# =============================================================================

# Policy: Deny writes to home directory
for op in privileges.operations:
  if op.type == "file_write" and op.resource.startswith("$HOME"):
    deny()

# Policy: Allow only HTTPS downloads from trusted domains
for op in privileges.operations:
  if op.type == "network_get":
    if not op.resource.startswith("https://"):
      deny()
    allowed_domains = ["github.com", "releases.hashicorp.com"]
    if not any(op.resource.contains(d) for d in allowed_domains):
      deny()

# Policy: Deny destructive commands on system paths
for op in privileges.operations:
  if op.type == "file_write":
    if "rm -rf" in op.command and op.resource.startswith("/"):
      deny()

# Policy: Require cross-validation for high-confidence
if privileges.confidence < 0.7:
  require_manual_review()

# =============================================================================
# EXAMPLE VALID OUTPUT
# =============================================================================

# Given this script:
#   78: mkdir -p "${TEMP_EXTRACT_DIR}"
#   90: command rm -rf "${TEMP_EXTRACT_DIR}"
#   95: curl -fSL "${DOWNLOAD_URL}" | tar -xzf - -C "${TEMP_EXTRACT_DIR}"
#   111: command rm -rf "${FINAL_DIR}"
#   128: command rm -f ~/.local/bin/agent

# The manifest should contain:

privileges:
  operations:
    - line: 78
      command: mkdir -p "${TEMP_EXTRACT_DIR}"
      resource: ${TEMP_EXTRACT_DIR}
      type: file_write
      
    - line: 90
      command: command rm -rf "${TEMP_EXTRACT_DIR}"
      resource: ${TEMP_EXTRACT_DIR}
      type: file_write
      
    - line: 95
      command: curl -fSL "${DOWNLOAD_URL}" | tar -xzf - -C "${TEMP_EXTRACT_DIR}"
      resource: ${DOWNLOAD_URL}
      type: network_get
      
    - line: 111
      command: command rm -rf "${FINAL_DIR}"
      resource: ${FINAL_DIR}
      type: file_write
      
    - line: 128
      command: command rm -f ~/.local/bin/agent ~/.local/bin/cursor-agent
      resource: ~/.local/bin/agent
      type: file_write
      
    - line: 128
      command: command rm -f ~/.local/bin/agent ~/.local/bin/cursor-agent
      resource: ~/.local/bin/cursor-agent
      type: file_write
  
  files:
    read: []
    write:
      - path: ${TEMP_EXTRACT_DIR}
        line: 78
        command: mkdir -p "${TEMP_EXTRACT_DIR}"
      - path: ${TEMP_EXTRACT_DIR}
        line: 90
        command: command rm -rf "${TEMP_EXTRACT_DIR}"
      - path: ${FINAL_DIR}
        line: 111
        command: command rm -rf "${FINAL_DIR}"
      - path: ~/.local/bin/agent
        line: 128
        command: command rm -f ~/.local/bin/agent ~/.local/bin/cursor-agent
      - path: ~/.local/bin/cursor-agent
        line: 128
        command: command rm -f ~/.local/bin/agent ~/.local/bin/cursor-agent
  network:
    get:
      - url: ${DOWNLOAD_URL}
        line: 95
        command: curl -fSL "${DOWNLOAD_URL}" | tar -xzf - -C "${TEMP_EXTRACT_DIR}"
    put: []

# =============================================================================
# PROMPT ENGINEERING REFERENCE
# =============================================================================

# When prompting the LLM to extract operations, use this format:

"""
Analyze this command and identify resources it affects.

COMMAND (line {line_number}):
{full_command_line}

SURROUNDING CONTEXT:
{±3 lines of context}

What file paths, URLs, or other resources does this command affect?
Be specific - extract the exact paths/URLs as they appear or as variables expand.

JSON format:
{{"line":{line},"command":"{full_command}","resources":["/path/or/url"]}}

JSON only. No conversational text.
"""

# Key points:
# 1. Include line number in prompt
# 2. Include FULL command line (not abbreviated)
# 3. Include surrounding context for variable resolution
# 4. Request specific format with examples
# 5. Enforce JSON-only output with system prompt
