# three-cubes-minus-three-prod-dvd-sum

The sum a+b+c divides the symmetric expression a cubed plus b cubed plus c cubed minus three times abc.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The sum a+b+c divides the symmetric expression a cubed plus b cubed plus c cubed minus three times abc. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Provide the cofactor a^2+b^2+c^2-ab-bc-ca as a Dvd witness, then close with ring. Verified to build (lake env lean).
