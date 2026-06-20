# fib-prod-cross-shift-nat-int

Over the integers, fib(n+1) times fib(n+2) minus fib(n) times fib(n+3) equals (-1)^n.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** Over the integers, fib(n+1) times fib(n+2) minus fib(n) times fib(n+3) equals (-1)^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Cast to ℤ, rewrite fib(n+3)=fib(n+1)+fib(n+2) and fib(n+2)=fib(n)+fib(n+1) via Int.fib_add_two, reduce to Cassini fib(n)*fib(n+2)-fib(n+1)^2, ring with parity. Verified to build (lake env lean).
