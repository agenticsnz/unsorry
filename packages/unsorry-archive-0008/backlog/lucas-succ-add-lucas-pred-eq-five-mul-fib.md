# lucas-succ-add-lucas-pred-eq-five-mul-fib

The sum of the Lucas numbers at n+2 and n equals five times fib(n+1) (stated with a +1 index shift to keep terms in Nat).

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog.
- **Reference:** The sum of the Lucas numbers at n+2 and n equals five times fib(n+1) (stated with a +1 index shift to keep terms in Nat). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Rewrite fib(n+3)=fib(n+1)+fib(n+2), fib(n+2)=fib n+fib(n+1), and fib(n+1)=fib n+fib(n-1) via fib_add_two; omega collapses to 5*fib(n+1). Verified to build (lake env lean) at sourcing.
