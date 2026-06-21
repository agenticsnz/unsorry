# dvd-sixteen-odd-pow-four-sub-one

For every odd integer n, 16 divides n^4 minus 1.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every odd integer n, 16 divides n^4 minus 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** obtain ⟨k,rfl⟩ from Odd; ∀ x : ZMod 16, (2*x+1)^4 - 1 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean).
