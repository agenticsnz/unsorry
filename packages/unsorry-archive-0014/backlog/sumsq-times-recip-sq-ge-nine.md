# sumsq-times-recip-sq-ge-nine

For positive reals, (a²+b²+c²)(1/a²+1/b²+1/c²) ≥ 9 (Cauchy–Schwarz on squares).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Cauchy–Schwarz / AM–HM applied to a²,b²,c². Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** Identity: (a^2+b^2+c^2)(1/a^2+1/b^2+1/c^2) − 9 = (a^2(b^2−c^2)^2+b^2(c^2−a^2)^2+c^2(a^2−b^2)^2)/(a^2 b^2 c^2) ≥ 0. Verified to compile: rw [← sub_nonneg]; establish that identity by `field_simp; ring`; then `positivity`.
