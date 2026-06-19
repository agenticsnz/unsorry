# gcd-n-factorial-succ-eq-one

For positive n, n is coprime to n factorial plus one.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** For positive n, n is coprime to n factorial plus one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** n divides n! (Nat.dvd_factorial), so gcd n (n!+1) = gcd n 1 = 1 via the add-multiple reduction. Verified to build (lake env lean).
