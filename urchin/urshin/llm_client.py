"""
LLM Clients for urshin.

Supports:
- OpenAI (GPT-4o-mini, GPT-4)
- NVIDIA API (OpenAI-compatible)
- Anthropic (Claude 3)
- Ollama (local models)
"""

import os
import json


class OpenAIClient:
    """OpenAI API client (also works with NVIDIA and other OpenAI-compatible APIs)"""
    
    def __init__(self, api_key=None, model=None, base_url=None):
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        self.model = model or os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
        self.base_url = base_url or os.environ.get("OPENAI_BASE_URL")
    
    async def complete(self, prompt: str, response_format: str = "text", **kwargs) -> str:
        """Generate completion"""
        from openai import AsyncOpenAI
        
        # Use custom base URL if provided (for NVIDIA, etc.)
        client_kwargs = {"api_key": self.api_key}
        if self.base_url:
            client_kwargs["base_url"] = self.base_url
        
        client = AsyncOpenAI(**client_kwargs)
        
        response_kwargs = {}
        if response_format == "json":
            response_kwargs["response_format"] = {"type": "json_object"}
        
        response = await client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            temperature=kwargs.get("temperature", 0.1),
            max_tokens=kwargs.get("max_tokens", 500),
            **response_kwargs
        )
        
        return response.choices[0].message.content


class AnthropicClient:
    """Anthropic API client"""
    
    def __init__(self, api_key=None, model="claude-3-haiku-20240307"):
        self.api_key = api_key or os.environ.get("ANTHROPIC_API_KEY")
        self.model = model
    
    async def complete(self, prompt: str, response_format: str = "text", **kwargs) -> str:
        """Generate completion"""
        from anthropic import AsyncAnthropic
        
        client = AsyncAnthropic(api_key=self.api_key)
        
        system = ""
        if response_format == "json":
            system = "Respond with JSON only. No other text."
        
        response = await client.messages.create(
            model=self.model,
            max_tokens=kwargs.get("max_tokens", 500),
            system=system,
            messages=[{"role": "user", "content": prompt}]
        )
        
        return response.content[0].text


class OllamaClient:
    """Ollama local model client"""
    
    def __init__(self, base_url=None, model="llama3.1"):
        self.base_url = base_url or os.environ.get("OLLAMA_URL", "http://localhost:11434")
        self.model = model
    
    async def complete(self, prompt: str, response_format: str = "text", **kwargs) -> str:
        """Generate completion"""
        import aiohttp
        
        url = f"{self.base_url}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": kwargs.get("temperature", 0.1),
                "num_predict": kwargs.get("max_tokens", 500),
            }
        }
        
        if response_format == "json":
            payload["format"] = "json"
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as response:
                response.raise_for_status()
                data = await response.json()
                return data.get("response", "")
