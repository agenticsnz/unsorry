"""Gate B — in-repo deterministic validator for unsorry coordination records.

ADR-003 / SPEC-003-A/B/C/D. Python 3.12, stdlib only. CLI:

    python3 -m tools.gate_b validate <tree-root> [--at ISO8601Z] \\
        [--goals-root PATH] [--json]
"""
from .validator import Violation, validate_tree

__all__ = ["Violation", "validate_tree"]
