# schur-inequality-deg-one

Schur's inequality of degree one: for nonnegative reals the symmetric sum a(a−b)(a−c)+b(b−a)(b−c)+c(c−a)(c−b) is nonnegative.

- **Source:** #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md.
- **Reference:** Schur's inequality, exponent t=1 (a classical named inequality; not in mathlib for ordered fields — mathlib's `schur_*` are the Schur complement / Schur product, unrelated).
- **Absence:** no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17
- **Triviality:** non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17
- **Difficulty:** 4
- **Decomposition sketch:** WLOG a≥b≥c reduces it to (a−b)^2(a+b−c)+c(a−c)(b−c)≥0. Verified to compile: `nlinarith [mul_nonneg ha (sq_nonneg (a-b)), mul_nonneg hb (sq_nonneg (b-c)), mul_nonneg hc (sq_nonneg (c-a)), mul_nonneg ha (sq_nonneg (a-c)), mul_nonneg hb (sq_nonneg (a-b)), mul_nonneg hc (sq_nonneg (b-c)), mul_nonneg (mul_nonneg ha hb) hc]`. Decomposition edge: expands to the inequality a^3+b^3+c^3+3abc ≥ Σ_sym a^2 b.
