# dvd-thirtytwo-odd-pow-eight-sub-one

For every odd integer n, 32 divides n^8 minus 1.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every odd integer n, 32 divides n^8 minus 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** obtain ⟨k,rfl⟩ from Odd; ∀ x : ZMod 32, (2*x+1)^8 - 1 = 0 by decide; transfer lemma (build-verified). Verified to build (lake env lean).
