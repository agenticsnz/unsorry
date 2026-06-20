# fourth-power-mod-twentyfive-mem

Every fourth power modulo 25 lies in the arithmetic-progression set {0,1,6,11,16,21}.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every fourth power modulo 25 lies in the arithmetic-progression set {0,1,6,11,16,21}. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Reduce to n % 25 via Nat.pow_mod and decide; nonzero residues are exactly 1 mod 5. Verified to build (lake env lean).
