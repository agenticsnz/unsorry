# nesbitt-inequality

Nesbitt's inequality: for positive reals a, b, c, a/(b+c) + b/(c+a) + c/(a+b) ≥ 3/2.

- **Source:** Nesbitt's inequality (1903), a classic three-variable cyclic inequality; AoPS/olympiad canon.
- **Reference:** 3/2 ≤ a/(b+c) + b/(c+a) + c/(a+b) for a,b,c > 0. mathlib has `inner_mul_le_norm_mul_norm` and `div_add_div_same`-style lemmas but no Nesbitt lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — a three-variable rational inequality is not one-shot-closable by the battery.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** Positivity of the three denominators (`0 < b+c`, etc. by `linarith`). Clear denominators: two `div_add_div` rewrites combine the three fractions, then `le_div_iff₀ (mul_pos …)` moves 3/2 across the positive common denominator (b+c)(c+a)(a+b). The polynomial residual is closed by `nlinarith` with the SOS hints `sq_nonneg (a−b)`, `sq_nonneg (b−c)`, `sq_nonneg (c−a)` together with the pairwise `mul_pos` positivity facts. Candidate for decompose→recompose if the cleared `nlinarith` is too wide in one shot.
