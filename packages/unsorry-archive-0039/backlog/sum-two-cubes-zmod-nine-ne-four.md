# sum-two-cubes-zmod-nine-ne-four

A sum of two integer cubes is never congruent to 4 modulo 9 (cubes mod 9 are 0,1,8).

- **Source:** #400 Identity Engine (ADR-043) — modular-arith family.
- **Reference:** A sum of two integer cubes is never congruent to 4 modulo 9 (cubes mod 9 are 0,1,8). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Cast to ZMod 9; decide exhausts all 81 residue pairs, none of whose cube sums equal 4.
