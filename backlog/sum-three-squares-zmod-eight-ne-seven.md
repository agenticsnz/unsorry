# sum-three-squares-zmod-eight-ne-seven

A sum of three integer squares is never congruent to 7 modulo 8 (a case of the three-square theorem).

- **Source:** #400 Identity Engine (ADR-043) — modular-arith family.
- **Reference:** A sum of three integer squares is never congruent to 7 modulo 8 (a case of the three-square theorem). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Cast to ZMod 8 and let decide exhaust all 8^3 residue triples, none summing to 7.
