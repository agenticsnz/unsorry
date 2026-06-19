# cheb-three-cube-ge-sum-times-sumsq

Chebyshev's sum inequality (degree three): for nonnegative reals, (a+b+c)(a²+b²+c²) ≤ 3(a³+b³+c³).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Chebyshev sum inequality, three-term degree-three instance. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** Difference equals a sum of (a+b)(a−b)^2-type nonnegative terms. Verified to compile: `nlinarith [mul_nonneg (add_nonneg ha hb) (sq_nonneg (a-b)), mul_nonneg (add_nonneg hb hc) (sq_nonneg (b-c)), mul_nonneg (add_nonneg hc ha) (sq_nonneg (c-a))]`.
