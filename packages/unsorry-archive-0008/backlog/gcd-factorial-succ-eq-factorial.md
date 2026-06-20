# gcd-factorial-succ-eq-factorial

The gcd of n! and (n+1)! equals n!, since (n+1)! = (n+1)·n!.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of n! and (n+1)! equals n!, since (n+1)! = (n+1)·n!. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Nat.factorial_succ gives (n+1)! = (n+1)*n!, so n! | (n+1)! and gcd is n! by Nat.gcd_eq_left. Verified to build (lake env lean).
