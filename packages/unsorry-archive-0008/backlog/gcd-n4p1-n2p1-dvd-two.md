# gcd-n4p1-n2p1-dvd-two

The gcd of n^4+1 and n^2+1 always divides 2.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog.
- **Reference:** The gcd of n^4+1 and n^2+1 always divides 2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** n^4+1 = (n^2+1)(n^2-1) + 2, so the Euclidean remainder is 2 and gcd ∣ 2. Verified to build (lake env lean) at sourcing.
