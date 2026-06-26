# gcd-6n5-6n11-eq-one

The values 6n+5 and 6n+11 are coprime for every natural number n.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The values 6n+5 and 6n+11 are coprime for every natural number n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** g divides their difference 6; and 6n+5 is coprime to 6 (it is 5 mod 6), so g | gcd(6n+5,6)=1. Verified to build (lake env lean).
