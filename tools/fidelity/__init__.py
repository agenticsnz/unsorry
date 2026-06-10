"""Statement-fidelity normalizer and differ (ADR-003, SPEC-003-C, PR-5).

Normalizes AISP theorem statements (NFC → canonical symbol table →
whitespace removal → α-renaming) so that two independent translations of the
same English statement can be compared byte-for-byte, and content-addresses
the canonical form with SHA-256.
"""

from .extract import ExtractError, extract_stmt, statement_from_source
from .normalize import first_divergence, line_sha, normalize, statement_sha

__all__ = [
    "ExtractError",
    "extract_stmt",
    "statement_from_source",
    "first_divergence",
    "line_sha",
    "normalize",
    "statement_sha",
]
