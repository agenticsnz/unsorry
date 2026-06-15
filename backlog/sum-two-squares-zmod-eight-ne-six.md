# sum-two-squares-zmod-eight-ne-six

A sum of two integer squares is never congruent to 6 modulo 8.

- **Source:** #400 Identity Engine (ADR-043) — modular-arith family.
- **Reference:** A sum of two integer squares is never congruent to 6 modulo 8. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Cast to ZMod 8; decide checks all 64 residue pairs, whose square sums avoid 6.
