# cassini-nat-fib-int

Over the integers, fib n times fib(n+2) minus fib(n+1) squared equals (-1)^(n+1) (a Cassini-form identity for Nat.fib).

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** Over the integers, fib n times fib(n+2) minus fib(n+1) squared equals (-1)^(n+1) (a Cassini-form identity for Nat.fib). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Induction on n: base by decide/norm_num; step rewrites fib(n+3)=fib(n+1)+fib(n+2) and fib(n+2)=fib n+fib(n+1) (cast fib_add_two), then ring_nf and use pow_succ on (-1). Verified to build (lake env lean).
