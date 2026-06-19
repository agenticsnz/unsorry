# dvd-120-five-consecutive-product

120 (=5!) divides n·(n^2-1)·(n^2-4), the product of five consecutive integers centred at n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 120 (=5!) divides n·(n^2-1)·(n^2-4), the product of five consecutive integers centred at n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** ∀ x : ZMod 120, x*(x^2-1)*(x^2-4)=0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean) at sourcing.
