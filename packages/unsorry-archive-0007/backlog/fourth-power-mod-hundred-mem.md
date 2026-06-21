# fourth-power-mod-hundred-mem

The last two decimal digits of a fourth power are always one of twelve values {00,01,16,21,25,36,41,56,61,76,81,96}.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog.
- **Reference:** The last two decimal digits of a fourth power are always one of twelve values {00,01,16,21,25,36,41,56,61,76,81,96}. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** n^4 mod 100 depends only on n % 100; Nat.pow_mod then decide over 100 residues with raised maxRecDepth. Verified to build (lake env lean) at sourcing.
