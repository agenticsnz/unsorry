# sum-icc-k-sq-add-one-mul-factorial-eq-pronic-factorial

The sum over k from 1 to n of (k^2+1)*k! telescopes to n*(n+1)!.

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog.
- **Reference:** The sum over k from 1 to n of (k^2+1)*k! telescopes to n*(n+1)!. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n with Finset.sum_Icc_succ_top; use (k^2+1)k! step against n((n+1)!) telescope, Nat.factorial_succ + ring/omega. Verified to build (lake env lean) at sourcing.
