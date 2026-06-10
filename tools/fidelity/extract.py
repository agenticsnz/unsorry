"""Extract the ``stmt≜…`` statement from an AISP translation record.

Translation records (SPEC-003-C) carry exactly one statement inside their
``⟦Σ:Stmt⟧`` block, either on its own line::

    ⟦Σ:Stmt⟧{
      stmt≜∀n∈ℕ:0+n≡n
    }

or inline: ``⟦Σ:Stmt⟧{stmt≜∀n∈ℕ:0+n≡n}``.
"""

from __future__ import annotations

import re

_STMT_BLOCK = "⟦Σ:Stmt⟧"
_BLOCK_OPEN = re.compile(re.escape(_STMT_BLOCK) + r"\s*\{")
_STMT_FIELD = re.compile(r"stmt≜(.*)")


class ExtractError(ValueError):
    """The text does not contain a well-formed ⟦Σ:Stmt⟧ statement."""


def extract_stmt(text: str) -> str:
    """Return the raw statement from a translation record's ⟦Σ:Stmt⟧ block."""
    opened = _BLOCK_OPEN.search(text)
    if opened is None:
        raise ExtractError(f"no {_STMT_BLOCK} block found")
    rest = text[opened.end():]
    field = _STMT_FIELD.search(rest.split("\n", 1)[0]) or _STMT_FIELD.search(rest)
    if field is None:
        raise ExtractError(f"no stmt≜ field inside the {_STMT_BLOCK} block")
    stmt = field.group(1).split("\n", 1)[0].strip()
    # Inline form ⟦Σ:Stmt⟧{stmt≜…}: drop the block's own closing brace, but
    # only when it is unbalanced (the statement itself may contain {…} sets).
    if stmt.endswith("}") and stmt.count("}") > stmt.count("{"):
        stmt = stmt[:-1].rstrip()
    if not stmt:
        raise ExtractError("stmt≜ field is empty")
    return stmt


def statement_from_source(text: str) -> str:
    """Interpret ``text`` as a translation record if it contains a ⟦Σ:Stmt⟧
    block, otherwise as a raw statement."""
    if _STMT_BLOCK in text:
        return extract_stmt(text)
    return text.strip()
