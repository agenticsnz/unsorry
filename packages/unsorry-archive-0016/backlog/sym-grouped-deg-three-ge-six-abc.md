# sym-grouped-deg-three-ge-six-abc

For nonnegatives the grouped symmetric degree-three form a^2(b+c)+... is at least 6abc.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** For nonnegatives the grouped symmetric degree-three form a^2(b+c)+... is at least 6abc. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** nlinarith with mul_nonneg ha (sq_nonneg (b-c)) and cyclic AM-GM pair hints. Verified to build (lake env lean).
