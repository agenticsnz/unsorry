"""Shared test setup for tools.fidelity.

Puts the repository root on sys.path so `tools.fidelity` is importable as a
namespace package regardless of where pytest is invoked from, and exposes
the common fixture paths used by more than one test module (DRY).
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

PAIRS_DIR = Path(__file__).resolve().parent / "pairs"
VALID_TREE = REPO_ROOT / "tools" / "gate_b" / "tests" / "fixtures" / "valid_tree"


def pair_ids(directory: Path) -> list[str]:
    """Sorted pair ids (the NN prefixes) found in a pairs directory."""
    return sorted({p.name.split("-")[0] for p in directory.glob("*-a.txt")})


def read_pair(directory: Path, pair_id: str) -> tuple[str, str]:
    """Return the (a, b) raw statement texts for a planted pair."""
    a = (directory / f"{pair_id}-a.txt").read_text(encoding="utf-8")
    b = (directory / f"{pair_id}-b.txt").read_text(encoding="utf-8")
    return a, b
