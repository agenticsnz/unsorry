"""Shared test setup for the seedkit family generators/writers.

Puts the repository root and the seedkit directory on ``sys.path`` so the
script-style modules (``gen_*``, ``mkfiles_*``, ``_artifact``, ``_words``) and
``tools.lean_sig`` are importable regardless of where pytest is invoked from.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SEEDKIT = REPO_ROOT / "tools" / "seedkit"

for _p in (REPO_ROOT, SEEDKIT):
    if str(_p) not in sys.path:
        sys.path.insert(0, str(_p))
