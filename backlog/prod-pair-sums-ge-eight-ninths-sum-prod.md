# prod-pair-sums-ge-eight-ninths-sum-prod

For nonnegative reals, 9(a+b)(b+c)(c+a) ≥ 8(a+b+c)(ab+bc+ca).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Classical symmetric product inequality. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 4
- **Decomposition sketch:** 9(a+b)(b+c)(c+a) − 8(a+b+c)(ab+bc+ca) = a(b−c)^2+b(c−a)^2+c(a−b)^2 ≥ 0. Verified to compile: `nlinarith [mul_nonneg ha (sq_nonneg (b-c)), mul_nonneg hb (sq_nonneg (c-a)), mul_nonneg hc (sq_nonneg (a-b))]`.
