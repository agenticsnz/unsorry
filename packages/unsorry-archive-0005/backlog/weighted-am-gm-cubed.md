# weighted-am-gm-cubed

For nonneg reals x,y, 2x³+y³ ≥ 3x²y — a weighted AM–GM, since 2x³+y³−3x²y = (x−y)²(2x+y).

- **Source:** Classic real inequality (library-growth batch, #400 plan Phase 3). The project had almost no inequalities; this seeds the SOS/nlinarith family.
- **Reference:** For nonneg reals x,y, 2x³+y³ ≥ 3x²y — a weighted AM–GM, since 2x³+y³−3x²y = (x−y)²(2x+y). mathlib has the abstract Cauchy–Schwarz / power-mean lemmas but not this concrete polynomial form as a named lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — the battery has `linarith` but **not** `nlinarith`/`positivity`, so the SOS gap is not one-shot-closable.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** `nlinarith [mul_nonneg hx (sq_nonneg (x-y)), mul_nonneg hy (sq_nonneg (x-y))]`. Verified to build (lake env lean).
