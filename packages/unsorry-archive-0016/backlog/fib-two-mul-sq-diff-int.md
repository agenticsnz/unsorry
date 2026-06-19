# fib-two-mul-sq-diff-int

fib(2n) = fib(n+1)² − fib(n−1)², a difference-of-squares doubling formula.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** fib(2n) = fib(n+1)² − fib(n−1)², a difference-of-squares doubling formula. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Start from Int.fib_two_mul, rewrite fib(n+1) and fib(n-1) via fib_add_two, and close with ring. Verified to build (lake env lean).
