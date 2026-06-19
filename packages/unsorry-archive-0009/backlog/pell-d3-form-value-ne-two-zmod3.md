# pell-d3-form-value-ne-two-zmod3

The form x²−3y² never takes a value congruent to 2 (mod 3), so x²−3y²=2 (and =−1) are unsolvable.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** The form x²−3y² never takes a value congruent to 2 (mod 3), so x²−3y²=2 (and =−1) are unsolvable. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** push the form into ZMod 3 where it equals x²; decide that x²∈{0,1} over the three residues, never 2. Verified to build (lake env lean) at sourcing.
