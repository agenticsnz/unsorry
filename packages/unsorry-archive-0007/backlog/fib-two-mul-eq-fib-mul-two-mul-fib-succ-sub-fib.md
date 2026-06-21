# fib-two-mul-eq-fib-mul-two-mul-fib-succ-sub-fib

The Fibonacci doubling identity in additive form: F(2n) + F(n)^2 equals F(n)·2F(n+1).

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog (#610).
- **Reference:** The Fibonacci doubling identity in additive form: F(2n) + F(n)^2 equals F(n)·2F(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Derive from fib_add with m=n minus one, i.e. F(2n)=F(n)(2F(n+1)-F(n)); rearrange over ℕ avoiding subtraction by moving F(n)^2 to the left. Verified to build (lake env lean).
