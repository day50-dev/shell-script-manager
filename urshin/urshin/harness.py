"""
urshin - Urshi Manifest Generator

Multi-pass sequential bootstrap inference with LOGLEVEL support.
"""

import asyncio
import hashlib
import json
import subprocess
import tempfile
import os
import re
import sys
from dataclasses import dataclass, field
from typing import Optional, Dict, List
from urllib.parse import urlparse

# LOGLEVEL support
LOGLEVEL = os.environ.get("LOGLEVEL", "INFO").upper()

def log(level, msg, *args):
    """Simple logging with LOGLEVEL support - outputs to stderr"""
    if level == "DEBUG" and LOGLEVEL == "DEBUG":
        print(f"DEBUG: {msg % args if args else msg}", file=sys.stderr)
    elif level in ["INFO", "WARNING", "ERROR"]:
        print(f"{level}: {msg % args if args else msg}", file=sys.stderr)


@dataclass
class InferenceContext:
    """Shared context between inference passes"""
    url: str
    normalized_url: str = ""
    script_content: str = ""
    checksum: str = ""
    homepage: Optional[str] = None
    readme_url: Optional[str] = None
    readme_content: Optional[str] = None
    source_url: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    license: Optional[str] = None
    bash_syntax_valid: bool = False
    shellcheck: Dict = field(default_factory=dict)
    privileges: Dict = field(default_factory=dict)
    compliances: List[str] = field(default_factory=list)
    confidence_scores: Dict = field(default_factory=dict)
    flags: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)


class InferenceHarness:
    """Multi-pass sequential bootstrap inference harness"""
    
    def __init__(self, api_key: str, base_url: str, model: str, brave_key: str = None, verbose: bool = False):
        self.api_key = api_key
        self.base_url = base_url
        self.model = model
        self.brave_key = brave_key
        self.verbose = verbose
        self.context: Optional[InferenceContext] = None
        
        # Validate required config
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY is required")
        if not self.base_url:
            raise ValueError("OPENAI_BASE_URL is required")
        if not self.model:
            raise ValueError("OPENAI_MODEL is required")
    
    async def infer(self, url: str) -> Dict:
        """Run full inference pipeline"""
        self.context = InferenceContext(url=url)
        
        try:
            await self._fetch_script(url)
            await self._pass0_static_analysis()
            await self._pass1_find_homepage()
            await self._pass2_find_readme()
            await self._pass3_infer_name()
            await self._pass4_find_source()
            await self._pass5_find_license()
            await self._pass6_detect_compliance()
            await self._pass7_analyze_privileges()
            self._calculate_confidence()
            return self._build_result()
        except Exception as e:
            self.context.errors.append(str(e))
            log("DEBUG", "Error: %s", e)
            return self._build_result()
    
    async def _fetch_script(self, url: str):
        """Fetch script content and normalize URL"""
        from .url_parser import normalize_url, fetch_content
        
        normalized = normalize_url(url)
        self.context.normalized_url = normalized
        content = await fetch_content(normalized)
        self.context.script_content = content
        self.context.checksum = hashlib.sha256(content.encode()).hexdigest()
        
        log("INFO", "✓ Fetched %d bytes", len(content))
    
    async def _pass0_static_analysis(self):
        """Run bash -n and shellcheck"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
            f.write(self.context.script_content)
            temp_path = f.name
        
        try:
            result = subprocess.run(['bash', '-n', temp_path], capture_output=True, text=True, timeout=10)
            self.context.bash_syntax_valid = (result.returncode == 0)
            log("INFO", "✓ bash -n: %s", "valid" if self.context.bash_syntax_valid else "INVALID")
            
            try:
                result = subprocess.run(['shellcheck', '-f', 'json', temp_path], capture_output=True, text=True, timeout=30)
                self.context.shellcheck = json.loads(result.stdout) if result.stdout else {"comments": []}
                log("INFO", "✓ shellcheck: %d issues", len(self.context.shellcheck.get("comments", [])))
            except FileNotFoundError:
                self.context.shellcheck = {"comments": []}
        finally:
            os.unlink(temp_path)
    
    async def _pass1_find_homepage(self):
        """Pass 1: URL → Homepage"""
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        prompt = f"""Extract homepage URL from script URL. JSON only.

SCRIPT URL: {self.context.normalized_url}

{{"homepage": "https://...", "confidence": 0.0-1.0}}
"""
        
        result = await self._call_llm(client, prompt)
        if result:
            self.context.homepage = result.get("homepage")
            self.context.confidence_scores["homepage"] = result.get("confidence", 0.0)
            log("INFO", "✓ Pass 1 (homepage): %s (%.0f%%)", self.context.homepage, result.get("confidence", 0) * 100)
    
    async def _pass2_find_readme(self):
        """Pass 2: URL + Homepage → Readme"""
        from openai import AsyncOpenAI
        
        if not self.context.homepage:
            log("WARNING", "⚠ Pass 2 (readme): No homepage, skipping")
            return
        
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        prompt = f"""Find README/documentation URL. JSON only.

HOMEPAGE: {self.context.homepage}

{{"readme_url": "https://...", "confidence": 0.0-1.0}}
"""
        
        result = await self._call_llm(client, prompt)
        if result and result.get("readme_url"):
            self.context.readme_url = result.get("readme_url")
            self.context.confidence_scores["readme"] = result.get("confidence", 0.0)
            log("INFO", "✓ Pass 2 (readme): %s", self.context.readme_url)
        else:
            log("WARNING", "⚠ Pass 2 (readme): No readme found")
    
    async def _pass3_infer_name(self):
        """Pass 3: URL + Homepage + Readme → Name + Description"""
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        context_parts = [f"SCRIPT URL: {self.context.normalized_url}"]
        if self.context.homepage:
            context_parts.append(f"HOMEPAGE: {self.context.homepage}")
        
        prompt = f"""Extract project name and description. JSON only.

{chr(10).join(context_parts)}

{{"name": "project-name", "description": "one sentence", "confidence": 0.9}}
"""
        
        result = await self._call_llm(client, prompt)
        if result:
            self.context.name = result.get("name")
            self.context.description = result.get("description")
            self.context.confidence_scores["name"] = result.get("confidence", 0.0)
            log("INFO", "✓ Pass 3 (name): %s", self.context.name)
    
    async def _pass4_find_source(self):
        """Pass 4: Homepage → Source Code"""
        from openai import AsyncOpenAI
        
        if not self.context.homepage:
            return
        
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        prompt = f"""Find source code repository. JSON only.

HOMEPAGE: {self.context.homepage}

{{"source_url": "https://github.com/...", "confidence": 0.0-1.0}}
"""
        
        result = await self._call_llm(client, prompt)
        if result and result.get("source_url"):
            self.context.source_url = result.get("source_url")
            self.context.confidence_scores["source"] = result.get("confidence", 0.0)
            log("INFO", "✓ Pass 4 (source): %s", self.context.source_url)
    
    async def _pass5_find_license(self):
        """Pass 5: Source/Readme → License"""
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        prompt = f"""Detect license type. JSON only.

HOMEPAGE: {self.context.homepage or "N/A"}

{{"license": "MIT"|"Apache-2.0"|"GPL-3.0"|null, "confidence": 0.0-1.0}}
"""
        
        result = await self._call_llm(client, prompt)
        if result and result.get("license"):
            self.context.license = result.get("license")
            self.context.confidence_scores["license"] = result.get("confidence", 0.0)
            log("INFO", "✓ Pass 5 (license): %s", self.context.license)
    
    async def _pass6_detect_compliance(self):
        """Pass 6: Homepage/Readme → Compliances"""
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        prompt = f"""Detect compliance certifications. JSON only.

HOMEPAGE: {self.context.homepage or "N/A"}

{{"compliances": ["HIPAA", "SOC-2"], "confidence": 0.0-1.0}}
"""
        
        result = await self._call_llm(client, prompt)
        if result and result.get("compliances"):
            self.context.compliances = result.get("compliances", [])
            log("INFO", "✓ Pass 6 (compliance): %s", ", ".join(self.context.compliances))
    
    async def _pass7_analyze_privileges(self):
        """
        Pass 7: Script → Tools/Privileges
        
        Two-pass approach:
        1. String match for important commands
        2. LLM extracts resources with context
        
        Output conforms to POLICY_MANIFEST_SCHEMA.md
        """
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url)
        
        # Important commands
        IMPORTANT_COMMANDS = [
            'rm', 'shred', 'dd', 'truncate',
            'cp', 'mv', 'chmod', 'chown', 'tee',
            'cat', 'grep', 'head', 'tail',
            'curl', 'wget',
            'mkdir', 'rmdir',
            'ssh', 'scp', 'rsync',
            'docker', 'kubectl', 'podman',
            'aws', 'gcloud', 'az',
            'terraform', 'ansible',
        ]
        
        # Format script with line numbers (XML tags)
        lines = self.context.script_content.split('\n')
        formatted_lines = []
        for i, line in enumerate(lines, 1):
            escaped = line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
            formatted_lines.append(f'<line number="{i}">{escaped}</line>')
        numbered_script = '\n'.join(formatted_lines)
        
        # Pass 7a: Find commands via string matching
        operations = []
        
        for cmd in IMPORTANT_COMMANDS:
            for i, line in enumerate(lines, 1):
                if re.search(rf'\b{cmd}\b', line):
                    # Skip comments
                    if line.strip().startswith('#'):
                        continue
                    
                    # Get context (±3 lines)
                    start = max(1, i - 3)
                    end = min(len(lines), i + 3)
                    context = '\n'.join(formatted_lines[start-1:end])
                    
                    # Extract command name only
                    cmd_match = re.search(rf'\b{cmd}\b', line)
                    command_name = cmd_match.group(0) if cmd_match else cmd
                    
                    prompt = f"""Extract file paths, URLs, or resources from this command.

COMMAND (line {i}):
{line}

CONTEXT:
{context}

Rules:
1. Extract ACTUAL paths/URLs from the command (e.g., ${{VAR}}, ~/.bashrc, /tmp/file, https://...)
2. Do NOT use placeholder values like "/path"
3. If no specific resource, output empty array

{{"line": {i}, "command": "{command_name}", "full_command": "{line.strip()}", "resources": ["${{VAR}}", "~/.bashrc"]}}
"""
                    try:
                        result = await self._call_llm(client, prompt)
                        if self._validate_tool_schema(result):
                            if result.get("resources"):
                                operations.append(result)
                    except Exception as e:
                        log("DEBUG", "Error processing line %d: %s", i, e)
        
        # Remove duplicates
        seen = set()
        unique_ops = []
        for op in operations:
            key = (op.get("line"), op.get("command", "")[:50])
            if key not in seen:
                seen.add(key)
                unique_ops.append(op)
        operations = unique_ops
        
        log("INFO", "✓ Pass 7a: %d tools found", len(operations))
        
        # Build output - tools is the primary list
        all_tools = []
        files_read, files_write, network_get = [], [], []
        
        for op in operations:
            resources_list = op.get("resources", [])
            line = op.get("line", 0)
            command = op.get("command", "").strip()
            full_command = op.get("full_command", "").strip()
            
            for r in resources_list:
                tool_entry = {
                    "line": line,
                    "command": command,
                    "full_command": full_command,
                    "resource": r,
                    "type": self._get_tool_type(full_command, r)
                }
                all_tools.append(tool_entry)
                
                if r.startswith("http"):
                    network_get.append({"url": r, "line": line, "command": full_command})
                elif r.startswith("/") or r.startswith("$") or r.startswith("~"):
                    if tool_entry["type"] == "file_write":
                        files_write.append({"path": r, "line": line, "command": full_command})
                    else:
                        files_read.append({"path": r, "line": line, "command": full_command})
        
        self.context.privileges = {
            "files": {"read": files_read, "write": files_write},
            "network": {"get": network_get, "put": []},
            "tools": all_tools,
            "dynamic": []
        }
        self.context.confidence_scores["privileges"] = 0.8
        
        log("INFO", "✓ Pass 7: %d tools", len(all_tools))
    
    def _get_tool_type(self, command: str, resource: str) -> str:
        """Determine tool type from command and resource"""
        cmd_lower = command.lower()
        
        if resource.startswith("http"):
            if any(x in cmd_lower for x in [" -x post", " -x put", " -d ", " --data"]):
                return "network_put"
            return "network_get"
        
        if any(t in cmd_lower for t in ["rm ", "rm\t", ">>", "> ", "tee ", "cp ", "mv ", "chmod ", "chown ", "truncate "]):
            return "file_write"
        
        return "file_read"
    
    def _validate_tool_schema(self, tool: dict) -> bool:
        """Validate tool conforms to POLICY_MANIFEST_SCHEMA.md"""
        if not isinstance(tool, dict):
            return False
        
        required = ["line", "command", "full_command", "resources"]
        for field in required:
            if field not in tool:
                return False
        
        if not isinstance(tool.get("line"), int):
            return False
        if not isinstance(tool.get("command"), str):
            return False
        if not isinstance(tool.get("full_command"), str):
            return False
        if not isinstance(tool.get("resources"), list):
            return False
        
        # Command must be single word
        if ' ' in tool.get("command", "").strip():
            return False
        
        return True
    
    async def _call_llm(self, client, prompt: str) -> Optional[Dict]:
        """Call LLM and extract JSON"""
        try:
            response = await client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "Output ONLY valid JSON. No conversational text."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.0,
                max_tokens=400
            )
            content = response.choices[0].message.content.strip()
            
            # Extract JSON from response
            match = re.search(r'\{.*\}', content, re.DOTALL)
            if match:
                return json.loads(match.group())
        except Exception:
            pass
        return None
    
    def _calculate_confidence(self):
        """Calculate overall confidence"""
        scores = self.context.confidence_scores
        weights = {
            "homepage": 0.20,
            "readme": 0.10,
            "name": 0.20,
            "description": 0.15,
            "source": 0.10,
            "license": 0.10,
            "privileges": 0.15,
        }
        
        total = sum(scores.get(key, 0.5) * weight for key, weight in weights.items())
        self.context.confidence_scores["overall"] = round(total, 2)
        
        if total >= 0.85:
            status = "auto_approved"
        elif total >= 0.7:
            status = "needs_light_review"
        elif total >= 0.5:
            status = "needs_full_review"
        else:
            status = "rejected"
        
        self.context.confidence_scores["status"] = status
    
    def _build_result(self) -> Dict:
        """Build final result"""
        import yaml
        
        manifest = {
            "name": self.context.name or "unknown",
            "description": self.context.description or "",
            "url": self.context.normalized_url,
            "homepage": self.context.homepage or "",
            "readme": self.context.readme_url or "",
            "source": self.context.source_url or "",
            "license": self.context.license or "",
            "checksum": f"sha256:{self.context.checksum}",
            "compliances": self.context.compliances,
            "privileges": self.context.privileges,
        }
        
        yaml_output = yaml.dump(manifest, default_flow_style=False, sort_keys=False)
        
        return {
            "status": self.context.confidence_scores.get("status", "failed"),
            "confidence": self.context.confidence_scores.get("overall", 0.0),
            "manifest": manifest,
            "manifest_yaml": yaml_output,
            "flags": self.context.flags,
            "errors": self.context.errors,
        }
