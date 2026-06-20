# sum-range-lucas-shift-nat

The sum of L(i+1)=fib(i)+fib(i+2) over the first n indices equals fib(n+1)+fib(n+3)−3.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog (#610).
- **Reference:** The sum of L(i+1)=fib(i)+fib(i+2) over the first n indices equals fib(n+1)+fib(n+3)−3. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induct on n with Finset.sum_range_succ, using the partial-sum identity sum fib = fib(n+1)-1 twice, then omega. Verified to build (lake env lean).
