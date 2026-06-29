# sum-cubes-sym-divisible-by-quadratic

The symmetric quadratic a²+b²+c²-ab-bc-ca divides a³+b³+c³-3abc.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The symmetric quadratic a²+b²+c²-ab-bc-ca divides a³+b³+c³-3abc. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** exact ⟨a + b + c, by ring⟩. Verified to build (lake env lean).
