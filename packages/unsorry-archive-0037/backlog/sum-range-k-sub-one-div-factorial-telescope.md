# sum-range-k-sub-one-div-factorial-telescope

Reserved-shape variant: a factorial telescope whose summand (k-1)/(k+1)! collapses to a boundary term.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog.
- **Reference:** Reserved-shape variant: a factorial telescope whose summand (k-1)/(k+1)! collapses to a boundary term. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction; rewrite (k-1)/(k+1)! as 1/(k+1)! difference shifted, but state via Icc 1 n form below; keep as factorial telescope distinct from k/(k+1)!. Verified to build (lake env lean) at sourcing.
