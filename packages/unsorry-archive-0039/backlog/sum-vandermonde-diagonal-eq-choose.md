# sum-vandermonde-diagonal-eq-choose

The diagonal Vandermonde convolution, summing C(n,k) times C(m,k) over k, equals C(n+m,n).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The diagonal Vandermonde convolution, summing C(n,k) times C(m,k) over k, equals C(n+m,n). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Rewrite C(m,k)=C(m,m-k) via choose_symm to turn the same-index product into the standard Vandermonde shape, then apply Nat.add_choose_eq. Verified to build (lake env lean).
