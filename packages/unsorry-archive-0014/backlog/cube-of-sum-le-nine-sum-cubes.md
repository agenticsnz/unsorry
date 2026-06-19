# cube-of-sum-le-nine-sum-cubes

Power-mean inequality (cube form): for nonnegative reals, (a+b+c)³ ≤ 9(a³+b³+c³).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Power-mean (cubic) inequality, three-term instance. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** Equivalent to the cubic power-mean ((a+b+c)/3)^3 ≤ (a^3+b^3+c^3)/3. Verified to compile: `nlinarith [mul_nonneg (add_nonneg ha hb) (sq_nonneg (a-b)), mul_nonneg (add_nonneg hb hc) (sq_nonneg (b-c)), mul_nonneg (add_nonneg hc ha) (sq_nonneg (c-a)), mul_nonneg ha (sq_nonneg (a-b)), mul_nonneg hb (sq_nonneg (b-c)), mul_nonneg hc (sq_nonneg (c-a))]`.
