# sum-sixth-ge-cyclic-quartic-sq

For all reals, the sum of sixth powers dominates the cyclic sum a⁴b²+b⁴c²+c⁴a²: a⁶+b⁶+c⁶ ≥ a⁴b²+b⁴c²+c⁴a².

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Cyclic degree-six SOS inequality. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** Per term 2a^6+b^6−3a^4 b^2 = (a^2−b^2)^2(2a^2+b^2) ≥ 0; summing the three AM–GM bounds gives the result. Verified to compile: `nlinarith [mul_nonneg (sq_nonneg (a^2-b^2)) (by positivity : (0:ℝ) ≤ 2*a^2+b^2), mul_nonneg (sq_nonneg (b^2-c^2)) (by positivity : (0:ℝ) ≤ 2*b^2+c^2), mul_nonneg (sq_nonneg (c^2-a^2)) (by positivity : (0:ℝ) ≤ 2*c^2+a^2)]`.
