# gcd-nsq1-n1-dvd-two

The gcd of n^2+1 and n+1 always divides 2.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of n^2+1 and n+1 always divides 2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** n^2+1 = (n+1)(n-1) + 2, so g | (n^2+1) and g | (n+1) forces g | 2. Verified to build (lake env lean).
