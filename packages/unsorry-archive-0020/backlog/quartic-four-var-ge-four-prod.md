# quartic-four-var-ge-four-prod

Four-variable AM–GM on fourth powers: for all reals, a⁴+b⁴+c⁴+d⁴ ≥ 4abcd.

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Four-variable AM–GM instance. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** Chain a^4+b^4≥2a^2b^2, c^4+d^4≥2c^2d^2, and 2a^2b^2+2c^2d^2≥4abcd. Verified to compile: `nlinarith [sq_nonneg (a^2-b^2), sq_nonneg (c^2-d^2), sq_nonneg (a*b-c*d), sq_nonneg (a*b+c*d)]`.
