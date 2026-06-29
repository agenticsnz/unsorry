"""Shared subprocess double for intake tests (ADR-099 / SPEC-099-A).

Protocol §8: test doubles live in tests only, never in application code. The real
``lake`` calls (``lake exe cache get``, ``lake env lean``) are injected via a ``runner``
seam, so these tests are hermetic — no Lean, no network. The double records every call
(argv + cwd) so a test can assert *where* a build ran (the keystone: under the suite
``_verify`` context, not the repo root), and picks a return code per call so a test can
simulate a build failure (pin drift) or a battery-closed (glue) statement.
"""
from __future__ import annotations

import subprocess
from collections.abc import Callable
from pathlib import Path
from types import SimpleNamespace


class FakeRunner:
    """A ``subprocess.run`` stand-in.

    Return code per call, in order:
      * ``lake exe cache get``      → ``cache_rc``
      * ``lake env lean <file>``    → ``rc_for_lean(contents, path)`` if given, else ``default_rc``
      * anything else               → ``default_rc``

    ``rc_for_lean`` receives the *contents* of the ``.lean`` file argv points at (so a
    test can branch on the statement) and its path (so it can tell the real-statement
    build apart from the ``TrivialityProbe.lean`` battery probe).
    """

    def __init__(
        self,
        *,
        default_rc: int = 0,
        cache_rc: int = 0,
        rc_for_lean: Callable[[str, str], int] | None = None,
    ) -> None:
        self.calls: list[SimpleNamespace] = []
        self.default_rc = default_rc
        self.cache_rc = cache_rc
        self.rc_for_lean = rc_for_lean

    def __call__(self, argv, *, cwd=None, capture_output=False, text=False, timeout=None, **_kw):
        argv = tuple(str(a) for a in argv)
        rc = self._rc(argv)
        self.calls.append(SimpleNamespace(argv=argv, cwd=cwd))
        return subprocess.CompletedProcess(argv, rc, stdout="", stderr="")

    def _rc(self, argv: tuple[str, ...]) -> int:
        if argv[:4] == ("lake", "exe", "cache", "get"):
            return self.cache_rc
        if argv[:3] == ("lake", "env", "lean") and self.rc_for_lean is not None:
            path = argv[-1]
            try:
                contents = Path(path).read_text(encoding="utf-8")
            except OSError:
                contents = ""
            return self.rc_for_lean(contents, path)
        return self.default_rc

    # -- convenience accessors ------------------------------------------------
    @property
    def cwds(self) -> list[str | None]:
        return [c.cwd for c in self.calls]

    def lean_calls(self) -> list[SimpleNamespace]:
        return [c for c in self.calls if c.argv[:3] == ("lake", "env", "lean")]

    def cache_calls(self) -> list[SimpleNamespace]:
        return [c for c in self.calls if c.argv[:4] == ("lake", "exe", "cache", "get")]
