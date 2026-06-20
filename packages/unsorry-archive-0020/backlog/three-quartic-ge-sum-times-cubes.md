# three-quartic-ge-sum-times-cubes

Chebyshev's sum inequality (degree four): for nonnegative reals, (a+b+c)(a³+b³+c³) ≤ 3(a⁴+b⁴+c⁴).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Chebyshev sum inequality, degree-four instance. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** Difference equals Σ (a−b)^2(a^2+ab+b^2) ≥ 0. Verified to compile: `nlinarith [mul_nonneg (sq_nonneg (a-b)) (add_nonneg (add_nonneg (sq_nonneg a) (mul_nonneg ha hb)) (sq_nonneg b)), mul_nonneg (sq_nonneg (b-c)) (add_nonneg (add_nonneg (sq_nonneg b) (mul_nonneg hb hc)) (sq_nonneg c)), mul_nonneg (sq_nonneg (c-a)) (add_nonneg (add_nonneg (sq_nonneg c) (mul_nonneg hc ha)) (sq_nonneg a))]`.
