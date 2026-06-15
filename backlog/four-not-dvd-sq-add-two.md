# four-not-dvd-sq-add-two

4 never divides n^2 + 2, since n^2 mod 4 is 0 or 1.

- **Source:** #400 Identity Engine (ADR-043) — modular-arith family.
- **Reference:** 4 never divides n^2 + 2, since n^2 mod 4 is 0 or 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Divisibility gives n^2+2 = 0 in ZMod 4; decide rules out all four residues.
