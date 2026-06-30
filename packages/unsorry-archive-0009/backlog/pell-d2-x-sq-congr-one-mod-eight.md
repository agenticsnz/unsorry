# pell-d2-x-sq-congr-one-mod-eight

For every integer solution of x²−2y²=1 the x-coordinate satisfies x²≡1 (mod 8), reflecting that x is odd.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** For every integer solution of x²−2y²=1 the x-coordinate satisfies x²≡1 (mod 8), reflecting that x is odd. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** x is odd (x²=1+2y²), and every odd square is ≡1 mod 8; push h into ZMod 8 and decide over the residues. Verified to build (lake env lean) at sourcing.
