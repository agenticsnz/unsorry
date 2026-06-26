# three-mul-fib-eq-fib-add-two-add-fib-sub-two

Three times fib(n+2) equals fib(n+4) plus fib n.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** Three times fib(n+2) equals fib(n+4) plus fib n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Express fib(n+4),fib(n+2) via fib_add_two in terms of fib n, fib(n+1); omega closes it (shift avoids Nat subtraction). Verified to build (lake env lean).
