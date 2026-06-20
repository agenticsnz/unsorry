# fib-add-five-eq-five-mul-fib-succ-add-three-mul-fib

fib(n+5) equals five times fib(n+1) plus three times fib n.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** fib(n+5) equals five times fib(n+1) plus three times fib n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Repeatedly rewrite fib(n+k) down to fib n and fib(n+1) using fib_add_two, then omega. Verified to build (lake env lean).
