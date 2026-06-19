# fourth-power-mod-eight-mem

Every fourth power is congruent to 0 or 1 modulo 8.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family.
- **Reference:** Every fourth power is congruent to 0 or 1 modulo 8. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Reduce n^4 % 8 to (n%8)^4 % 8 via Nat.pow_mod, then interval_cases on n%8 and decide each of the 8 residues.
