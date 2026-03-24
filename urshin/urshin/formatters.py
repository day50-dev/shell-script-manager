"""
Output formatters for urshi manifests.
"""

import yaml


def format_yaml(manifest: dict) -> str:
    """Format manifest as YAML using PyYAML"""
    return yaml.dump(manifest, default_flow_style=False, sort_keys=False)
