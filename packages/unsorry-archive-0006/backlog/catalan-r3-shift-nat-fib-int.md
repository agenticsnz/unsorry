# catalan-r3-shift-nat-fib-int

Over the integers, the square of fib(n+3) minus fib(n) times fib(n+6) equals four times (-1)^n, a Catalan identity at offset three.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** Over the integers, the square of fib(n+3) minus fib(n) times fib(n+6) equals four times (-1)^n, a Catalan identity at offset three. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Cast to ℤ, repeatedly expand fib(n+k) via Int.fib_add_two to fib(n),fib(n+1), reduce to Cassini, ring_nf with the (-1)^n parity term (fib(3)^2 = 4). Verified to build (lake env lean).
