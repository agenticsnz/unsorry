# gcd-np1-2np1-eq-one

Consecutive-ratio terms n+1 and 2n+1 are always coprime.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** Consecutive-ratio terms n+1 and 2n+1 are always coprime. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Euclid step: 2*(n+1)-(2n+1)=1, so gcd divides 1; Nat.Coprime via dvd_sub or omega after gcd_rec. Verified to build (lake env lean).
