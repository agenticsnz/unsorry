# fourth-power-mod-eighty-mem

Every fourth power is congruent to only 0, 1, 16 or 65 modulo 80.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog.
- **Reference:** Every fourth power is congruent to only 0, 1, 16 or 65 modulo 80. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 80 residues collapse to 4 quartic residues; Nat.pow_mod plus decide over n % 80 with raised maxRecDepth. Verified to build (lake env lean) at sourcing.
