# fib-add-two-sq-sub-fib-sq-eq-fib-two-mul-add-two

The difference of the squares fib(n+2)^2 - fib(n)^2 equals fib(2n+2).

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** The difference of the squares fib(n+2)^2 - fib(n)^2 equals fib(2n+2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Rewrite via fib_add (fib(2n+2)=fib(n+1)(2fib n+fib(n+1))) and factor the difference of squares with fib(n+2)=fib(n+1)+fib n; ring after a Nat-subtraction guard. Verified to build (lake env lean).
