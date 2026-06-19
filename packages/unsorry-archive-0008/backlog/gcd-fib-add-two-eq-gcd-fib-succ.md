# gcd-fib-add-two-eq-gcd-fib-succ

gcd(F_n, F_{n+2}) equals gcd(F_n, F_{n+1}).

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** gcd(F_n, F_{n+2}) equals gcd(F_n, F_{n+1}). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** fib (n+2) = fib (n+1) + fib n; rewrite then use Nat.gcd_add_self_right / add-multiple gcd reduction. Verified to build (lake env lean).
