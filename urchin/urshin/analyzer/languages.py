"""
Language detection and syntax checker definitions.

Maps file types to their syntax checkers and permission pattern contexts.
"""

import os
import subprocess
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
from enum import Enum


class Language(Enum):
    """Supported languages for analysis."""
    SHELL = "shell"
    PYTHON = "python"
    JAVASCRIPT = "javascript"
    TYPESCRIPT = "typescript"
    GO = "go"
    RUST = "rust"
    UNKNOWN = "unknown"


@dataclass
class SyntaxChecker:
    """A syntax checking tool for a language."""
    name: str
    command: List[str]
    args_template: str = "{file}"
    parse_json: bool = False
    confidence_modifier: float = 1.0


@dataclass
class LanguageConfig:
    """Configuration for a programming language."""
    language: Language
    extensions: List[str]
    checkers: List[SyntaxChecker] = field(default_factory=list)
    mime_types: List[str] = field(default_factory=list)


# Language configurations with their syntax checkers
LANGUAGE_CONFIGS: Dict[str, LanguageConfig] = {
    "shell": LanguageConfig(
        language=Language.SHELL,
        extensions=[".sh", ".bash", ".zsh", ".fish"],
        mime_types=["application/x-sh", "application/x-shellscript"],
        checkers=[
            SyntaxChecker(
                name="bash_syntax",
                command=["bash", "-n"],
                args_template="{file}",
                parse_json=False,
                confidence_modifier=0.9
            ),
            SyntaxChecker(
                name="shellcheck",
                command=["shellcheck", "-f", "json"],
                args_template="{file}",
                parse_json=True,
                confidence_modifier=1.0
            ),
        ]
    ),
    "python": LanguageConfig(
        language=Language.PYTHON,
        extensions=[".py", ".pyw"],
        mime_types=["text/x-python", "application/python"],
        checkers=[
            SyntaxChecker(
                name="py_compile",
                command=["python", "-m", "py_compile"],
                args_template="{file}",
                parse_json=False,
                confidence_modifier=0.8
            ),
        ]
    ),
    "javascript": LanguageConfig(
        language=Language.JAVASCRIPT,
        extensions=[".js", ".mjs", ".cjs"],
        mime_types=["text/javascript", "application/javascript"],
        checkers=[
            SyntaxChecker(
                name="node_syntax",
                command=["node", "--check"],
                args_template="{file}",
                parse_json=False,
                confidence_modifier=0.9
            ),
        ]
    ),
    "typescript": LanguageConfig(
        language=Language.TYPESCRIPT,
        extensions=[".ts", ".tsx"],
        mime_types=["text/typescript", "application/typescript"],
        checkers=[
            SyntaxChecker(
                name="tsc",
                command=["npx", "tsc", "--noEmit", "--pretty", "false"],
                args_template="{file}",
                parse_json=False,
                confidence_modifier=0.7
            ),
        ]
    ),
    "go": LanguageConfig(
        language=Language.GO,
        extensions=[".go"],
        mime_types=["text/x-go"],
        checkers=[
            SyntaxChecker(
                name="go_build",
                command=["go", "build", "-n"],
                args_template="{file}",
                parse_json=False,
                confidence_modifier=0.6
            ),
        ]
    ),
    "rust": LanguageConfig(
        language=Language.RUST,
        extensions=[".rs"],
        mime_types=["text/x-rust"],
        checkers=[
            SyntaxChecker(
                name="cargo_check",
                command=["cargo", "check", "--message-format=json"],
                args_template="",
                parse_json=False,
                confidence_modifier=0.7
            ),
        ]
    ),
}


def detect_language(file_path: str) -> Language:
    """
    Detect the programming language of a file based on extension.

    Args:
        file_path: Path to the file

    Returns:
        Detected Language enum
    """
    _, ext = os.path.splitext(file_path)
    ext = ext.lower()

    for config in LANGUAGE_CONFIGS.values():
        if ext in config.extensions:
            return config.language

    return Language.UNKNOWN


def get_language_config(language: Language) -> Optional[LanguageConfig]:
    """Get the configuration for a language."""
    lang_name = language.value
    return LANGUAGE_CONFIGS.get(lang_name)


def get_available_checkers(language: Language) -> List[SyntaxChecker]:
    """Get all available syntax checkers for a language that are installed."""
    config = get_language_config(language)
    if not config:
        return []

    available = []
    for checker in config.checkers:
        # Check if command exists
        cmd = checker.command[0]
        try:
            subprocess.run([cmd, "--version"], capture_output=True, timeout=5)
            available.append(checker)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue

    return available