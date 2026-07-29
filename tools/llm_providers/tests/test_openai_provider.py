"""Tests for OpenAI provider base_url override + model passthrough (ADR-025).

No network: `session.post` is monkeypatched to a recorder that captures the
request payload and returns a canned completion.
"""
from pathlib import Path

import pytest

from tools.llm_providers.openai_provider import OpenAIProvider, OpenAIError

try:  # noqa: SIM105 - the point is to record availability, not to import lazily
    import requests as _requests
except ImportError:  # pragma: no cover - only on an install without requests
    _requests = None

# Constructing OpenAIProvider needs a real `requests` session. Marked rather than
# `pytest.importorskip`d at module scope, because the two missing-dependency tests
# at the bottom of this file must still run precisely when it is absent.
requires_requests = pytest.mark.skipif(
    _requests is None, reason="requests is not installed"
)


class FakeResp:
    def __init__(self, payload):
        self._payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self._payload


def recorder(captured, content="OK"):
    """Return a session.post stand-in that records the request json."""
    def post(url, json=None, timeout=None):
        captured["url"] = url
        captured["json"] = json
        return FakeResp({"choices": [{"message": {"content": content}}]})
    return post


def make_provider(monkeypatch, base_url=None, env_base=None, model_env_key="x"):
    monkeypatch.setenv("OPENAI_API_KEY", model_env_key)
    if env_base is not None:
        monkeypatch.setenv("OPENAI_BASE_URL", env_base)
    else:
        monkeypatch.delenv("OPENAI_BASE_URL", raising=False)
    return OpenAIProvider(base_url=base_url)


@requires_requests
def test_base_url_from_env(monkeypatch):
    p = make_provider(monkeypatch, env_base="http://localhost:11434/v1")
    assert p.base_url == "http://localhost:11434/v1"
    assert p.custom_endpoint is True


@requires_requests
def test_explicit_arg_beats_env(monkeypatch):
    p = make_provider(monkeypatch, base_url="http://h/v1", env_base="http://env/v1")
    assert p.base_url == "http://h/v1"
    assert p.custom_endpoint is True


@requires_requests
def test_default_endpoint(monkeypatch):
    p = make_provider(monkeypatch)
    assert p.base_url == OpenAIProvider.DEFAULT_BASE_URL
    assert p.custom_endpoint is False


@requires_requests
def test_model_passthrough_on_custom_endpoint(monkeypatch):
    p = make_provider(monkeypatch, env_base="http://localhost:11434/v1")
    captured = {}
    monkeypatch.setattr(p.session, "post", recorder(captured))
    # An arbitrary local model id must NOT raise "Unknown model"
    p.complete("hi", model="llama3.1:8b")
    assert captured["json"]["model"] == "llama3.1:8b"
    assert captured["url"] == "http://localhost:11434/v1/chat/completions"


@requires_requests
def test_model_rejected_on_default_endpoint(monkeypatch):
    p = make_provider(monkeypatch)  # default endpoint
    with pytest.raises(OpenAIError):
        p.complete("hi", model="llama3.1:8b")


@requires_requests
def test_tools_attached_on_custom_endpoint(monkeypatch):
    p = make_provider(monkeypatch, env_base="http://localhost:11434/v1")
    captured = {}
    monkeypatch.setattr(p.session, "post", recorder(captured))
    # llama3.1:8b is not in TOOL_MODELS, but a custom endpoint must still get tools
    p.complete("hi", model="llama3.1:8b", tools=[{"type": "function", "function": {"name": "f"}}])
    assert "tools" in captured["json"]
    assert captured["json"]["tool_choice"] == "auto"


@requires_requests
def test_tools_not_attached_for_non_tool_model_on_default(monkeypatch):
    p = make_provider(monkeypatch)  # default endpoint
    captured = {}
    monkeypatch.setattr(p.session, "post", recorder(captured))
    # o1 is a known model but not a TOOL_MODEL; default endpoint must not attach tools
    p.complete("hi", model="o1", tools=[{"type": "function", "function": {"name": "f"}}])
    assert "tools" not in captured["json"]


# --------------------------------------------------- missing optional dependency


def _load_isolated_provider(monkeypatch, *, with_requests):
    """Import a FRESH copy of the provider module under a throwaway name.

    Deliberately not `importlib.reload`: reloading rebinds the module's classes to
    new objects, so this file's top-level `from ... import OpenAIError` would stop
    matching what a later test raises — which is exactly how the first draft of
    these tests passed alone and failed in-suite. An isolated load leaves the
    canonical module untouched.
    """
    import importlib.util
    import sys as _sys

    if not with_requests:
        monkeypatch.setitem(_sys.modules, "requests", None)  # import requests -> ImportError
    spec = importlib.util.spec_from_file_location(
        "_isolated_openai_provider",
        Path(__file__).resolve().parents[1] / "openai_provider.py",
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # must not raise SystemExit
    return module


def test_module_import_survives_missing_requests(monkeypatch):
    """Importing the provider without `requests` must not kill the interpreter.

    The guard used to be `except ImportError: sys.exit(1)` at module scope, which
    aborted pytest's COLLECTION phase — `python3 -m pytest tools -q` (the command
    CLAUDE.md documents) died with `INTERNALERROR ... SystemExit: 1` and reported
    nothing about the ~1200 tests that never touch `requests`.
    """
    module = _load_isolated_provider(monkeypatch, with_requests=False)
    assert module.requests is None


def test_provider_construction_reports_missing_requests(monkeypatch):
    """The failure surfaces at construction, as an OpenAIError the CLI maps to exit 1."""
    module = _load_isolated_provider(monkeypatch, with_requests=False)
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test")
    with pytest.raises(module.OpenAIError) as excinfo:
        module.OpenAIProvider()
    assert "requests" in str(excinfo.value)
