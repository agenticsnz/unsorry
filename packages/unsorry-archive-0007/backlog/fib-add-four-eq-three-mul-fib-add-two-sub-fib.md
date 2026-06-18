# fib-add-four-eq-three-mul-fib-add-two-sub-fib

fib(n+4) equals three times fib(n+2) minus fib n.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** fib(n+4) equals three times fib(n+2) minus fib n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Expand fib(n+4),fib(n+3) via fib_add_two to express both sides in fib n, fib(n+1); discharge with omega (handles the Nat subtraction). Verified to build (lake env lean).
