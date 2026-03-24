"""
URL parser and normalizer for urshin.
"""

import re
from urllib.parse import urlparse


def normalize_url(url: str) -> str:
    """
    Normalize various URL formats to canonical HTTPS URLs.
    
    Examples:
        gh:user/repo/file.sh -> https://raw.githubusercontent.com/user/repo/main/file.sh
        gl:user/repo/file.sh -> https://gitlab.com/user/repo/-/raw/main/file.sh
    """
    url = url.strip()
    
    # GitHub shorthand: gh:user/repo/file.sh
    match = re.match(r'gh:([^/]+)/([^/]+)/(.+)', url)
    if match:
        user, repo, path = match.groups()
        return f"https://raw.githubusercontent.com/{user}/{repo}/main/{path}"
    
    # GitHub with branch: gh:user/repo@branch/file.sh
    match = re.match(r'gh:([^/]+)/([^/@]+)@([^/]+)/(.+)', url)
    if match:
        user, repo, branch, path = match.groups()
        return f"https://raw.githubusercontent.com/{user}/{repo}/{branch}/{path}"
    
    # GitLab shorthand: gl:user/repo/file.sh
    match = re.match(r'gl:([^/]+)/([^/]+)/(.+)', url)
    if match:
        user, repo, path = match.groups()
        return f"https://gitlab.com/{user}/{repo}/-/raw/main/{path}"
    
    # Ensure HTTPS
    if url.startswith('http://'):
        url = url.replace('http://', 'https://')
    elif not url.startswith('https://'):
        url = 'https://' + url
    
    return url


async def fetch_content(url: str) -> str:
    """Fetch content from URL"""
    import aiohttp
    
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            response.raise_for_status()
            return await response.text()
