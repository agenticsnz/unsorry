"""Tests for the openai `--prove` text-extraction fallback (ADR-102).

A proof-specialised model behind an OpenAI-compatible endpoint may answer in
plain text (the Lean module as a fenced block or bare prose) instead of emitting
a `Write` tool call. `process_conversation` must then extract the module from the
final text and write it to the target, while leaving the tool-call path untouched
and turning a genuine HTTP/transport failure into a non-zero exit (so ADR-016's
classifier is not fooled into reading infra failure as an empty answer).

No network: `requests.post` is monkeypatched to a scripted sequence of canned
chat-completion responses; `run_tool` writes to a real temp workdir.
"""
import json

import pytest
import requests

from tools.llm_providers import openai_cli

# openai_cli imports its provider classes via the script-friendly
# `llm_providers.*` path (its sys.path hack), so reference the exact OpenAIError
# class it raises rather than re-importing it under the `tools.*` package path
# (same source, distinct class object — `pytest.raises` matches by identity).
OpenAIError = openai_cli.OpenAIError


# --- helpers ---------------------------------------------------------------

class FakeResp:
    def __init__(self, payload, http_error=None):
        self._payload = payload
        self._http_error = http_error

    def raise_for_status(self):
        if self._http_error is not None:
            raise self._http_error

    def json(self):
        return self._payload


def assistant(content=None, tool_calls=None):
    """Build a `choices[0].message` chat-completion payload."""
    msg = {}
    if content is not None:
        msg["content"] = content
    if tool_calls is not None:
        msg["tool_calls"] = tool_calls
    return {"choices": [{"message": msg}]}


def write_call(call_id, file_path, content):
    return {
        "id": call_id,
        "type": "function",
        "function": {
            "name": "Write",
            "arguments": json.dumps({"file_path": file_path, "content": content}),
        },
    }


def scripted_post(responses):
    """Return a `requests.post` stand-in yielding `responses` in order."""
    seq = list(responses)

    def post(url, headers=None, json=None, timeout=None):
        return seq.pop(0)

    return post


@pytest.fixture
def provider(monkeypatch):
    monkeypatch.setenv("OPENAI_API_KEY", "x")
    monkeypatch.setenv("OPENAI_BASE_URL", "http://localhost:8080/v1")
    return openai_cli.OpenAIProvider()


TARGET = "library/Unsorry/Foo.lean"
PROMPT = "prove it\n\nTarget module file (relative to repo root): " + TARGET + "\n"


# --- extraction unit ------------------------------------------------------

def test_extract_prefers_lean_fence():
    text = "Here is the proof:\n```lean\nimport Mathlib\ntheorem foo : True := trivial\n```\nDone."
    out = openai_cli.extract_lean_module(text)
    assert out.strip() == "import Mathlib\ntheorem foo : True := trivial"


def test_extract_plain_fence_when_no_lean_tag():
    text = "```\nimport Mathlib\ntheorem foo : True := trivial\n```"
    out = openai_cli.extract_lean_module(text)
    assert out.strip() == "import Mathlib\ntheorem foo : True := trivial"


def test_extract_whole_content_when_no_fence():
    text = "  import Mathlib\ntheorem foo : True := trivial  "
    out = openai_cli.extract_lean_module(text)
    assert out.strip() == "import Mathlib\ntheorem foo : True := trivial"


def test_extract_first_lean_block_wins():
    text = "```lean\nFIRST\n```\nand later\n```lean\nSECOND\n```"
    assert openai_cli.extract_lean_module(text).strip() == "FIRST"


# --- acceptance criteria --------------------------------------------------

def test_no_tool_calls_with_fence_writes_target(provider, monkeypatch, tmp_path):
    """No tool_calls + fenced ```lean block → target written with block contents."""
    body = "import Mathlib\ntheorem foo : True := trivial"
    monkeypatch.setattr(requests, "post", scripted_post([
        FakeResp(assistant(content=f"Sure.\n```lean\n{body}\n```")),
    ]))
    openai_cli.process_conversation(provider, PROMPT, "leanstral", str(tmp_path), target=TARGET)
    written = (tmp_path / TARGET).read_text()
    assert written.strip() == body


def test_no_fence_writes_trimmed_content(provider, monkeypatch, tmp_path):
    """A response with no fence → the trimmed content is written verbatim."""
    body = "import Mathlib\ntheorem foo : True := trivial"
    monkeypatch.setattr(requests, "post", scripted_post([
        FakeResp(assistant(content=f"\n\n{body}\n\n")),
    ]))
    openai_cli.process_conversation(provider, PROMPT, "leanstral", str(tmp_path), target=TARGET)
    assert (tmp_path / TARGET).read_text().strip() == body


def test_tool_write_wins_no_double_write(provider, monkeypatch, tmp_path):
    """Model used the Write tool → that content stands; extraction does not override."""
    tool_body = "import Mathlib\ntheorem foo : True := by trivial\n"
    monkeypatch.setattr(requests, "post", scripted_post([
        FakeResp(assistant(tool_calls=[write_call("c1", TARGET, tool_body)])),
        # Final turn also includes a (different) fenced block that must be ignored.
        FakeResp(assistant(content="```lean\nSHOULD_NOT_BE_WRITTEN\n```")),
    ]))
    openai_cli.process_conversation(provider, PROMPT, "leanstral", str(tmp_path), target=TARGET)
    assert (tmp_path / TARGET).read_text() == tool_body


def test_http_error_raises_and_writes_nothing(provider, monkeypatch, tmp_path):
    """A 4xx/5xx → OpenAIError (caller exits non-zero), and no partial file written."""
    err = requests.exceptions.HTTPError("500 Server Error")
    monkeypatch.setattr(requests, "post", scripted_post([
        FakeResp(assistant(content="ignored"), http_error=err),
    ]))
    with pytest.raises(OpenAIError):
        openai_cli.process_conversation(provider, PROMPT, "leanstral", str(tmp_path), target=TARGET)
    assert not (tmp_path / TARGET).exists()


def test_transport_failure_raises(provider, monkeypatch, tmp_path):
    """A transport failure (connection error) → OpenAIError, no file."""
    def boom(url, headers=None, json=None, timeout=None):
        raise requests.exceptions.ConnectionError("refused")

    monkeypatch.setattr(requests, "post", boom)
    with pytest.raises(OpenAIError):
        openai_cli.process_conversation(provider, PROMPT, "leanstral", str(tmp_path), target=TARGET)
    assert not (tmp_path / TARGET).exists()


# --- target recovery from the prove prompt --------------------------------

def test_target_recovered_from_prompt():
    assert openai_cli.target_from_prompt(PROMPT) == TARGET


def test_target_from_prompt_none_when_absent():
    assert openai_cli.target_from_prompt("no target line here") is None
