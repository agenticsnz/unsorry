"""``python3 -m tools.adr_index`` entry point (ADR-073 / SPEC-073-A)."""
from __future__ import annotations

from tools.adr_index.generate import main

if __name__ == "__main__":
    raise SystemExit(main())
