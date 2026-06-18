# sum-sq-times-pairsum-ge-three-abc-sum

For nonnegative reals, (a²+b²+c²)(ab+bc+ca) ≥ 3abc(a+b+c).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Degree-four symmetric inequality. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 4
- **Decomposition sketch:** Two-stage: (a^2+b^2+c^2)(ab+bc+ca) ≥ (ab+bc+ca)^2 ≥ 3abc(a+b+c), using a^2+b^2+c^2 ≥ ab+bc+ca and ab+bc+ca ≥ 0. Verified to compile with hps : 0 ≤ a*b+b*c+c*a := by positivity; `nlinarith [mul_nonneg hps (sq_nonneg (a-b)), mul_nonneg hps (sq_nonneg (b-c)), mul_nonneg hps (sq_nonneg (c-a)), sq_nonneg (a*b-b*c), sq_nonneg (b*c-c*a), sq_nonneg (c*a-a*b)]`. Decomposition edges: ↦ (ab+bc+ca)^2 ≥ 3abc(a+b+c) and a^2+b^2+c^2 ≥ ab+bc+ca.
