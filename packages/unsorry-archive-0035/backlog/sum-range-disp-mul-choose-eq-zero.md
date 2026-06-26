# sum-range-disp-mul-choose-eq-zero

Over the integers the mean-centered sum of (2k-n) times C(n,k) vanishes.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Over the integers the mean-centered sum of (2k-n) times C(n,k) vanishes. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Split 2*sum(k*C)=n*2^n and n*sum(C)=n*2^n and cancel; or use the reflection k↦n-k that negates 2k-n while fixing C(n,k). Verified to build (lake env lean).
