# dvd-5040-seven-consecutive-product

5040 (=7!) divides n·(n^2-1)·(n^2-4)·(n^2-9), the product of seven consecutive integers centred at n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** 5040 (=7!) divides n·(n^2-1)·(n^2-4)·(n^2-9), the product of seven consecutive integers centred at n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** ∀ x : ZMod 5040, x*(x^2-1)*(x^2-4)*(x^2-9)=0 by decide (needs set_option maxRecDepth 100000, build-verified); transfer lemma. Verified to build (lake env lean).
