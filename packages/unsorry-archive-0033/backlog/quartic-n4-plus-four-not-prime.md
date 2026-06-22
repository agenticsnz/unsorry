# quartic-n4-plus-four-not-prime

For n at least 2 the value n^4+4 is composite (special case of the Sophie Germain identity).

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** For n at least 2 the value n^4+4 is composite (special case of the Sophie Germain identity). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Factor n^4+4 = (n^2-2n+2)(n^2+2n+2); show 1 < n^2-2n+2 by nlinarith then not_prime_mul. Verified to build (lake env lean).
