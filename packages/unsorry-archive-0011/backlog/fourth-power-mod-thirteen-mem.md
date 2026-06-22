# fourth-power-mod-thirteen-mem

Every fourth power is congruent to 0, 1, 3, or 9 modulo 13 (the quartic residues mod 13).

- **Source:** #400 Identity Engine (ADR-043) — power-residue family.
- **Reference:** Every fourth power is congruent to 0, 1, 3, or 9 modulo 13 (the quartic residues mod 13). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Reduce n^4 % 13 to (n%13)^4 % 13 via Nat.pow_mod, then interval_cases on n%13 and decide all 13 residues.
