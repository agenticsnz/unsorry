# consec-prod-succ-coprime

Any number n(n+1) is coprime to its successor.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog.
- **Reference:** Any number n(n+1) is coprime to its successor. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Direct instance of Nat.coprime_succ_self_right; the n*(n+1) shape blocks a one-line decide. Verified to build (lake env lean) at sourcing.
