# sum-range-succ-mul-choose-sq-eq

Twice the sum of (k+1) times C(n,k) squared equals (n+2) times the central coefficient C(2n,n).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Twice the sum of (k+1) times C(n,k) squared equals (n+2) times the central coefficient C(2n,n). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Split (k+1)*C^2 into k*C^2 and C^2, then combine sum_range_choose_sq=C(2n,n) with the k-weighted central convolution 2*sum(k*C^2)=n*C(2n,n). Verified to build (lake env lean).
