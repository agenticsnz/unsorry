"""Statement normalization pipeline (SPEC-003-C §Normalization, ADR-003).

``normalize`` applies, in this exact order:

1. NFC Unicode normalization.
2. Canonical symbol table (``symbols.CANONICAL``).
3. Whitespace removal — the statement grammar is symbolic; spaces are never
   significant in our statement subset.
4. α-renaming of bound variables to ``x₁,x₂,…`` in binding-occurrence order,
   respecting scope (inner binders shadow outer ones; free identifiers are
   untouched).

The result is a single UTF-8 line. ``statement_sha`` is the SHA-256 (lowercase
hex) of the UTF-8 bytes of that line — the content address used for the
fidelity gate and ``library/index/<sha>.aisp``.
"""

from __future__ import annotations

import hashlib
import unicodedata
from typing import NamedTuple

from .symbols import apply_symbol_table

# ── tokens ───────────────────────────────────────────────────────────────────

_SUBSCRIPT_DIGITS = "₀₁₂₃₄₅₆₇₈₉"
_TO_SUBSCRIPT = str.maketrans("0123456789", _SUBSCRIPT_DIGITS)

#: Binder-introducing glyphs of the statement subset (SPEC-003-C):
#: ∀vars∈Set: · ∀vars: · ∃vars: · ∃!var: · λvars.
_BINDERS = ("∃!", "∀", "∃", "λ")

_OPEN = {"(": ")", "⟨": "⟩", "[": "]", "{": "}", "⟦": "⟧"}
_CLOSE = frozenset(_OPEN.values())


class _Token(NamedTuple):
    kind: str  # "BINDER" | "IDENT" | "NUM" | "SYM"
    text: str


def _is_letter(ch: str) -> bool:
    return unicodedata.category(ch).startswith("L")


def _tokenize(text: str) -> list[_Token]:
    """Tokenize a whitespace-free canonical-alphabet statement.

    Identifiers are ASCII letter sequences, or a single non-ASCII Unicode
    letter, in both cases optionally followed by subscript digits (``x₁``,
    ``ℕ``, ``succ``, ``α₂``). Runs of ASCII digits are numeric literals.
    Everything else is a single-character symbol.
    """
    tokens: list[_Token] = []
    i = 0
    length = len(text)
    while i < length:
        ch = text[i]
        if ch == "∃" and text.startswith("∃!", i):
            tokens.append(_Token("BINDER", "∃!"))
            i += 2
        elif ch in "∀∃λ":
            tokens.append(_Token("BINDER", ch))
            i += 1
        elif ch.isascii() and ch.isalpha():
            j = i + 1
            while j < length and text[j].isascii() and text[j].isalpha():
                j += 1
            while j < length and text[j] in _SUBSCRIPT_DIGITS:
                j += 1
            tokens.append(_Token("IDENT", text[i:j]))
            i = j
        elif not ch.isascii() and _is_letter(ch):
            j = i + 1
            while j < length and text[j] in _SUBSCRIPT_DIGITS:
                j += 1
            tokens.append(_Token("IDENT", text[i:j]))
            i = j
        elif ch.isascii() and ch.isdigit():
            j = i + 1
            while j < length and text[j].isascii() and text[j].isdigit():
                j += 1
            tokens.append(_Token("NUM", text[i:j]))
            i = j
        else:
            tokens.append(_Token("SYM", ch))
            i += 1
    return tokens


# ── α-renaming ───────────────────────────────────────────────────────────────


def _canonical_name(n: int) -> str:
    return "x" + str(n).translate(_TO_SUBSCRIPT)


def _alpha_rename(text: str) -> str:
    """Rename bound variables to x₁,x₂,… in binding-occurrence order.

    Scope model: a binder's scope extends to the end of the innermost
    enclosing bracket group (binders have lowest precedence per the AISP
    grammar), so a later binder of the same name shadows for the remainder
    of that group. The set expression of a ``∈``-binder is rendered in the
    scope *outside* the binder (its variables are not yet bound there).
    Malformed binder heads are conservatively left untouched.
    """
    tokens = _tokenize(text)
    out: list[str] = []
    counter = 0

    def fresh() -> str:
        nonlocal counter
        counter += 1
        return _canonical_name(counter)

    def parse_binder(i: int, end: int) -> tuple[list[str], tuple[int, int] | None, int] | None:
        """Try to parse a binder head at ``i``; None if it is not one.

        Returns (var names, set-expression token range or None, body start).
        """
        binder = tokens[i].text
        j = i + 1
        if j >= end or tokens[j].kind != "IDENT":
            return None
        variables = [tokens[j].text]
        j += 1
        if binder != "∃!":  # ∃! binds exactly one variable
            while (
                j + 1 < end
                and tokens[j] == _Token("SYM", ",")
                and tokens[j + 1].kind == "IDENT"
            ):
                variables.append(tokens[j + 1].text)
                j += 2
        if binder == "λ":
            if j < end and tokens[j] == _Token("SYM", "."):
                return variables, None, j + 1
            return None
        if j < end and tokens[j] == _Token("SYM", "∈"):
            k = j + 1
            depth = 0
            while k < end:
                tok = tokens[k]
                if tok.kind == "SYM":
                    if tok.text in _OPEN:
                        depth += 1
                    elif tok.text in _CLOSE:
                        if depth == 0:
                            return None  # group closed before the binder colon
                        depth -= 1
                    elif tok.text == ":" and depth == 0:
                        break
                k += 1
            else:
                return None  # no colon: not a well-formed binder head
            if k == j + 1:
                return None  # empty set expression
            return variables, (j + 1, k), k + 1
        if j < end and tokens[j] == _Token("SYM", ":"):
            return variables, None, j + 1
        return None

    def walk(i: int, end: int, env: dict[str, str], closer: str | None) -> int:
        """Emit tokens[i:end], renaming under ``env``; stop after ``closer``."""
        while i < end:
            tok = tokens[i]
            if tok.kind == "SYM" and tok.text in _OPEN:
                out.append(tok.text)
                i = walk(i + 1, end, dict(env), _OPEN[tok.text])
            elif tok.kind == "SYM" and tok.text in _CLOSE:
                out.append(tok.text)
                i += 1
                if closer is not None:
                    return i  # end of this group (mismatched closer included)
            elif tok.kind == "BINDER":
                parsed = parse_binder(i, end)
                if parsed is None:
                    out.append(tok.text)
                    i += 1
                    continue
                variables, set_range, body_start = parsed
                renames = [fresh() for _ in variables]
                out.append(tok.text)
                out.append(",".join(renames))
                if set_range is not None:
                    out.append("∈")
                    # outer scope: this binder's variables are not bound here
                    walk(set_range[0], set_range[1], dict(env), None)
                out.append("." if tok.text == "λ" else ":")
                env.update(zip(variables, renames))
                i = body_start
            elif tok.kind == "IDENT":
                out.append(env.get(tok.text, tok.text))
                i += 1
            else:
                out.append(tok.text)
                i += 1
        return i

    walk(0, len(tokens), {}, None)
    return "".join(out)


# ── pipeline ─────────────────────────────────────────────────────────────────


def normalize(stmt: str) -> str:
    """Normalize a statement per SPEC-003-C (NFC → symbols → whitespace → α)."""
    text = unicodedata.normalize("NFC", stmt)
    text = apply_symbol_table(text)
    text = "".join(ch for ch in text if not ch.isspace())
    return _alpha_rename(text)


def line_sha(normalized_line: str) -> str:
    """SHA-256 lowercase hex of the UTF-8 bytes of an already-normalized line."""
    return hashlib.sha256(normalized_line.encode("utf-8")).hexdigest()


def statement_sha(stmt: str) -> str:
    """Content address of a statement: ``line_sha(normalize(stmt))``."""
    return line_sha(normalize(stmt))


def first_divergence(a: str, b: str) -> int | None:
    """Index of the first differing character, or None if a == b."""
    if a == b:
        return None
    for index, (ca, cb) in enumerate(zip(a, b)):
        if ca != cb:
            return index
    return min(len(a), len(b))
