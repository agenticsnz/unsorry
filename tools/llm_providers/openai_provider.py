"""OpenAI API provider for Unsorry swarm.

Supports chat completions with tool use for Lean proof generation.
Similar to OpenExec's OpenAI provider but adapted for Unsorry's needs.
"""

import json
import os
import sys
import time
from typing import Optional


# A missing optional dependency must NOT be fatal at import time. `sys.exit(1)`
# here aborted the interpreter during module import, which took pytest's whole
# COLLECTION phase down with it — `python3 -m pytest tools -q`, the command
# CLAUDE.md documents, died with `INTERNALERROR ... SystemExit: 1` on any machine
# without `requests`, reporting nothing about the ~1200 tests that do not need it.
# CI never caught it because gate-b runs three narrower paths. Defer the failure
# to construction instead, where OpenAIProvider actually needs a session; the CLI
# maps OpenAIError to a clean exit 1, so the operator sees the same message.
try:
    import requests
except ImportError:  # pragma: no cover - only on an install without requests
    requests = None

_REQUESTS_MISSING = (
    "the 'requests' library is required for the OpenAI provider. "
    "Install with: pip install requests"
)


class OpenAIError(Exception):
    """OpenAI API error."""
    def __init__(self, message: str, code: Optional[str] = None):
        self.message = message
        self.code = code
        super().__init__(message)


class OpenAIProvider:
    """OpenAI API provider for Unsorry."""
    
    DEFAULT_BASE_URL = "https://api.openai.com/v1"
    DEFAULT_TIMEOUT = 1800  # 30 minutes, matching UNSORRY_WALL
    
    # Model identifiers
    MODELS = {
        "gpt-4o": "gpt-4o",
        "gpt-4o-mini": "gpt-4o-mini",
        "gpt-4-turbo": "gpt-4-turbo",
        "gpt-4": "gpt-4",
        "o1": "o1",
        "o1-mini": "o1-mini",
        "o3-mini": "o3-mini",
    }
    
    # Models that support tool use
    TOOL_MODELS = {"gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4", "o3-mini"}
    
    # Reasoning models (o1, o3) have limitations
    REASONING_MODELS = {"o1", "o1-mini", "o3-mini"}
    
    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None):
        """Initialize OpenAI provider.
        
        Args:
            api_key: OpenAI API key (defaults to OPENAI_API_KEY env var)
            base_url: API base URL (defaults to OpenAI's endpoint)
        """
        if requests is None:
            raise OpenAIError(_REQUESTS_MISSING)
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            raise OpenAIError("OPENAI_API_KEY environment variable required")
        
        # Precedence: explicit arg → OPENAI_BASE_URL env → OpenAI's endpoint.
        # A non-default base_url is a custom OpenAI-compatible endpoint (local
        # Ollama/vLLM/LM Studio or a proxy); see ADR-025.
        self.base_url = base_url or os.environ.get("OPENAI_BASE_URL") or self.DEFAULT_BASE_URL
        self.custom_endpoint = self.base_url.rstrip("/") != self.DEFAULT_BASE_URL.rstrip("/")
        self.timeout = self.DEFAULT_TIMEOUT
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        })
    
    def complete(
        self,
        prompt: str,
        model: str = "gpt-4o",
        system: Optional[str] = None,
        tools: Optional[list] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> str:
        """Send a completion request to OpenAI.
        
        Args:
            prompt: The user prompt
            model: Model identifier
            system: Optional system message
            tools: Optional list of tool definitions
            temperature: Sampling temperature (not for reasoning models)
            max_tokens: Maximum completion tokens
            
        Returns:
            The model's response text
            
        Raises:
            OpenAIError: On API errors
        """
        # The allow-list guards typos against the real OpenAI endpoint. On a
        # custom endpoint (ADR-025) the operator's model id is authoritative —
        # local model ids like "llama3.1:8b" are arbitrary — so pass it through.
        if not self.custom_endpoint and model not in self.MODELS.values():
            raise OpenAIError(f"Unknown model: {model}")
        
        messages = []
        
        # Add system message if present and not a reasoning model
        if system and model not in self.REASONING_MODELS:
            messages.append({"role": "system", "content": system})
        
        # Add user prompt
        messages.append({"role": "user", "content": prompt})
        
        # Build request
        request_data = {
            "model": model,
            "messages": messages,
        }
        
        # Add optional parameters
        if max_tokens:
            request_data["max_completion_tokens"] = max_tokens
        
        if temperature is not None and model not in self.REASONING_MODELS:
            request_data["temperature"] = temperature
        
        # Add tools when the model is a known tool-capable model, or when a
        # custom endpoint is in effect (we trust the operator's model to speak
        # OpenAI tool-calling; ADR-025). The prove path bypasses this entirely.
        if tools and (self.custom_endpoint or model in self.TOOL_MODELS):
            request_data["tools"] = tools
            request_data["tool_choice"] = "auto"
        
        # Make request
        url = f"{self.base_url}/chat/completions"
        start_time = time.time()
        
        try:
            response = self.session.post(
                url,
                json=request_data,
                timeout=self.timeout,
            )
            response.raise_for_status()
        except requests.exceptions.Timeout:
            raise OpenAIError(f"Request timed out after {self.timeout}s")
        except requests.exceptions.RequestException as e:
            raise OpenAIError(f"Request failed: {e}")
        
        # Parse response
        try:
            data = response.json()
        except json.JSONDecodeError as e:
            raise OpenAIError(f"Invalid JSON response: {e}")
        
        if "error" in data:
            error = data["error"]
            raise OpenAIError(error.get("message", "Unknown error"), error.get("code"))
        
        # Extract content
        choices = data.get("choices", [])
        if not choices:
            raise OpenAIError("No choices in response")
        
        message = choices[0].get("message", {})
        content = message.get("content", "")
        
        # Handle tool calls if present
        tool_calls = message.get("tool_calls", [])
        if tool_calls:
            # Format tool calls in a way the agent can parse
            tool_output = []
            for tc in tool_calls:
                if tc.get("type") == "function":
                    func = tc.get("function", {})
                    tool_output.append({
                        "name": func.get("name"),
                        "arguments": func.get("arguments", "{}"),
                    })
            
            # Return both content and tool calls
            if tool_output:
                return json.dumps({
                    "content": content,
                    "tool_calls": tool_output,
                })
        
        return content or ""
    
    def prove(
        self,
        prompt: str,
        model: str = "gpt-4o",
        workdir: Optional[str] = None,
    ) -> str:
        """Generate a Lean proof using OpenAI.
        
        Args:
            prompt: The proof generation prompt
            model: Model to use
            workdir: Working directory (for context, not used by API)
            
        Returns:
            Generated Lean code
        """
        # System prompt for Lean proof generation
        system = """You are an expert in Lean 4 theorem proving. 
Your task is to write complete, correct Lean 4 proofs.
Use the available tools to read files, edit code, and run lake build to check your work.
Always produce valid Lean 4 syntax."""
        
        # Define tools for file operations and lake commands
        tools = [
            {
                "type": "function",
                "function": {
                    "name": "Read",
                    "description": "Read a file",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "file_path": {"type": "string"},
                        },
                        "required": ["file_path"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "Edit",
                    "description": "Edit a file",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "file_path": {"type": "string"},
                            "old_string": {"type": "string"},
                            "new_string": {"type": "string"},
                        },
                        "required": ["file_path", "old_string", "new_string"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "Write",
                    "description": "Write a file",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "file_path": {"type": "string"},
                            "content": {"type": "string"},
                        },
                        "required": ["file_path", "content"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "Bash",
                    "description": "Run a bash command",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "command": {"type": "string"},
                        },
                        "required": ["command"],
                    },
                },
            },
        ]
        
        return self.complete(
            prompt=prompt,
            model=model,
            system=system,
            tools=tools,
            temperature=0.1,  # Low temperature for deterministic proofs
        )


def main():
    """CLI entry point for OpenAI provider."""
    import argparse
    
    parser = argparse.ArgumentParser(description="OpenAI provider for Unsorry")
    parser.add_argument("--model", default="gpt-4o", help="Model to use")
    parser.add_argument("--prove", action="store_true", help="Use prove mode")
    parser.add_argument("--workdir", help="Working directory")
    parser.add_argument("--system", help="System prompt")
    parser.add_argument("--temperature", type=float, help="Temperature")
    parser.add_argument("prompt", nargs="?", help="Prompt (or read from stdin)")
    
    args = parser.parse_args()
    
    # Get prompt from args or stdin
    if args.prompt:
        prompt = args.prompt
    else:
        prompt = sys.stdin.read()
    
    if not prompt:
        print("Error: No prompt provided", file=sys.stderr)
        sys.exit(1)
    
    try:
        provider = OpenAIProvider()
        
        if args.prove:
            result = provider.prove(
                prompt=prompt,
                model=args.model,
                workdir=args.workdir,
            )
        else:
            result = provider.complete(
                prompt=prompt,
                model=args.model,
                system=args.system,
                temperature=args.temperature,
            )
        
        print(result)
        
    except OpenAIError as e:
        print(f"Error: {e.message}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)


if __name__ == "__main__":
    main()
