# alt-sum-range-choose-sq-eq-zero-odd

For odd n, the alternating sum of (-1)^k times the square of n-choose-k vanishes.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** For odd n, the alternating sum of (-1)^k times the square of n-choose-k vanishes. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Pair the term k with n-k: their signs differ (n odd) while C(n,k)^2 are equal, so they cancel via Finset.sum_involution / reflection over range. Verified to build (lake env lean).
