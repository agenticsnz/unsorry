"""``python3 -m tools.project_sync`` entry point (ADR-077 / SPEC-077-A)."""
from __future__ import annotations

import sys

from tools.project_sync.sync import main

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
