# pairsum-sq-le-three-sum-sq-products

For all reals, the square of the pairwise-product sum is at most three times the sum of squared pairwise products: (ab+bc+ca)² ≤ 3(a²b²+b²c²+c²a²).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Power-mean / Cauchy–Schwarz applied to (ab,bc,ca). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** 3·Σ(ab)^2 − (Σab)^2 = (ab−bc)^2+(bc−ca)^2+(ca−ab)^2 ≥ 0. Verified to compile: `nlinarith [sq_nonneg (a*b-b*c), sq_nonneg (b*c-c*a), sq_nonneg (c*a-a*b)]`.
