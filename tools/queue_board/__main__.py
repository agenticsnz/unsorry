"""``python3 -m tools.queue_board`` entry point (ADR-066 / SPEC-066-A)."""
from __future__ import annotations

from tools.queue_board.generate import main

if __name__ == "__main__":
    raise SystemExit(main())
