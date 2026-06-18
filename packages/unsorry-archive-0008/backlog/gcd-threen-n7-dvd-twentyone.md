# gcd-threen-n7-dvd-twentyone

The gcd of 3n and n+7 always divides 21.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of 3n and n+7 always divides 21. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** g | 3n and g | 3*(n+7)=3n+21; difference is 21, so g | 21. Verified to build (lake env lean).
