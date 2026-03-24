"""
Brave Search client for urshin.
"""

import os


class BraveSearchClient:
    """Brave Search API client"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get("BRAVE_API_KEY")
        self.base_url = "https://api.search.brave.com/res/v1"
    
    async def search(self, query: str, count: int = 10) -> list:
        """Perform web search"""
        if not self.api_key:
            return []
        
        import aiohttp
        
        headers = {
            "Accept": "application/json",
            "X-Subscription-Token": self.api_key
        }
        
        params = {
            "q": query,
            "count": min(count, 20)
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{self.base_url}/web/search",
                headers=headers,
                params=params
            ) as response:
                response.raise_for_status()
                data = await response.json()
                
                results = []
                for result in data.get("web", {}).get("results", []):
                    results.append({
                        "url": result.get("url"),
                        "title": result.get("title"),
                        "description": result.get("description"),
                    })
                
                return results
