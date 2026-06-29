# sum-cubes-sq-le-three-sum-sixth

For all reals, the square of the sum of cubes is at most three times the sum of sixth powers: (a³+b³+c³)² ≤ 3(a⁶+b⁶+c⁶).

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Power-mean / Cauchy–Schwarz applied to (a³,b³,c³). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 3
- **Decomposition sketch:** 3·Σa^6 − (Σa^3)^2 = (a^3−b^3)^2+(b^3−c^3)^2+(c^3−a^3)^2 ≥ 0. Verified to compile: `nlinarith [sq_nonneg (a^3-b^3), sq_nonneg (b^3-c^3), sq_nonneg (c^3-a^3)]`.
