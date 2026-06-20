# ravi-product-le-abc

Under the triangle-type nonnegativity conditions a+b−c, b+c−a, c+a−b ≥ 0, the product (a+b−c)(b+c−a)(c+a−b) is at most abc (IMO 1964 Problem 2).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** IMO 1964 Problem 2 (Ravi-substitution form). Not a named mathlib lemma.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 4
- **Decomposition sketch:** Equivalent to Schur degree-one after the Ravi substitution. Verified to compile: `nlinarith [mul_nonneg hab (sq_nonneg (a-b)), mul_nonneg hbc (sq_nonneg (b-c)), mul_nonneg hca (sq_nonneg (c-a)), mul_nonneg hab (sq_nonneg (b-c)), mul_nonneg hbc (sq_nonneg (c-a)), mul_nonneg hca (sq_nonneg (a-b)), mul_nonneg (mul_nonneg hab hbc) hca]`. Decomposition edge: ↦ schur-inequality-deg-one.
