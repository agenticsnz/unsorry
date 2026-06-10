"""Canonical symbol table for the statement-fidelity normalizer (SPEC-003-C §2).

Policy — conservative, typographic variants only. An alias is admitted to
``CANONICAL`` only when it is an unambiguous typographical or ASCII variant of
exactly one AISP glyph in our statement subset. Glyphs that carry *different
meanings* are never merged: ``≠`` (inequality of values) and ``≢``
(non-equivalence) stay distinct; ``→`` (function arrow) and ``⇒`` (implies)
stay distinct; ``·`` (multiplication) and ``×`` (product/Cartesian) stay
distinct; ``↔`` (iff) and ``⇔`` stay distinct. When in doubt, a glyph is left
out: a false MISMATCH costs one human review, a false MATCH corrupts the
content-addressed library.

Where both glyphs are AISP-native, the representative is the glyph used by the
AISP 5.1 Σ₅₁₂ alphabet (swarm/AI_GUIDE.md); ASCII digraphs map onto it.
"""

from __future__ import annotations

#: alias → representative. Keys are replaced; values are canonical and must
#: never themselves appear as keys (no chains — enforced by tests).
CANONICAL: dict[str, str] = {
    # Arrows: long / open-headed typographic variants of the function arrow.
    "⟶": "→",  # U+27F6 LONG RIGHTWARDS ARROW — length-only variant of U+2192
    "⇾": "→",  # U+21FE RIGHTWARDS OPEN-HEADED ARROW — head-style variant
    # Definition: "equal to by definition" is the same relation as AISP ≜.
    "≝": "≜",  # U+225D EQUAL TO BY DEFINITION → U+225C DELTA EQUAL TO
    ":=": "≔",  # ASCII digraph for assignment → U+2254 COLON EQUALS
    # Multiplication: representative is U+00B7 MIDDLE DOT, the glyph in the
    # AISP Σ₅₁₂ Ω-category alphabet. ASCII "*" is its keyboard variant.
    # U+00D7 "×" is NOT aliased: it denotes product/Cartesian product in AISP.
    "*": "·",
    # Logic: ASCII digraph/keyboard variants of the AISP connectives.
    "&&": "∧",  # C-family conjunction → U+2227 LOGICAL AND
    "||": "∨",  # C-family disjunction → U+2228 LOGICAL OR
    "!": "¬",  # C-family negation → U+00AC NOT SIGN ("∃!" and "!=" are
    #            matched first by the longest-match scanner, so a bare "!"
    #            is unambiguously negation)
    # Comparison: ASCII digraphs for the relational glyphs.
    "<=": "≤",  # → U+2264 LESS-THAN OR EQUAL TO
    ">=": "≥",  # → U+2265 GREATER-THAN OR EQUAL TO
    "!=": "≠",  # → U+2260 NOT EQUAL TO (inequality). Deliberately NOT ≢:
    #            non-equivalence is a different relation and stays distinct.
}

#: Multi-glyph tokens that must never be split by the alias scanner.
#: "∃!" is the exists-unique binder; without protection its "!" would be
#: rewritten to "¬".
PROTECTED: tuple[str, ...] = ("∃!",)

# Longest match first so digraphs ("!=", ":=", "<=", …) win over their
# single-character prefixes ("!", ":", "<", …).
_SCAN_ORDER: tuple[str, ...] = tuple(
    sorted(PROTECTED, key=len, reverse=True)
    + sorted(CANONICAL, key=len, reverse=True)
)


def apply_symbol_table(text: str) -> str:
    """Rewrite every alias in ``text`` to its canonical representative.

    Single deterministic left-to-right pass, longest match first; protected
    tokens are copied through untouched.
    """
    out: list[str] = []
    i = 0
    length = len(text)
    while i < length:
        for token in _SCAN_ORDER:
            if text.startswith(token, i):
                out.append(CANONICAL.get(token, token))
                i += len(token)
                break
        else:
            out.append(text[i])
            i += 1
    return "".join(out)
