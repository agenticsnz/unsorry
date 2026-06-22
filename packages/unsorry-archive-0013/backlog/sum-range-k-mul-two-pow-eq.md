# sum-range-k-mul-two-pow-eq

The sum of k·2^k for k from 0 to n-1 equals (n−2)·2ⁿ + 2.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog.
- **Reference:** The sum of k·2^k for k from 0 to n-1 equals (n−2)·2ⁿ + 2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; handle Nat subtraction by stating over ℤ or proving 2 ≤ result; ring_nf after expanding 2^(n+1). Verified to build (lake env lean) at sourcing.
