# catalan-r2-int-fib

Catalan's identity at offset 2: fib(n)² − fib(n−2)·fib(n+2) = (−1)^n.

- **Source:** #400 Identity Engine (ADR-043) — Fibonacci/Lucas family; promoted from candidate backlog.
- **Reference:** Catalan's identity at offset 2: fib(n)² − fib(n−2)·fib(n+2) = (−1)^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Expand fib(n±2) via Int.fib_add_two and reduce to Cassini fib_succ_mul_fib_pred_sub_fib_sq with ring. Verified to build (lake env lean) at sourcing.
