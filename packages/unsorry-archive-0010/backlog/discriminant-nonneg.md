# discriminant-nonneg

If a>0 and b²≤4ac, then ax²+bx+c ≥ 0 for all x (the discriminant nonnegativity criterion).

- **Source:** Classic elementary real inequality (#400 plan Phase 3 — library growth).
- **Reference:** If a>0 and b²≤4ac, then ax²+bx+c ≥ 0 for all x (the discriminant nonnegativity criterion). Not a named mathlib lemma in this concrete polynomial/abs form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — the battery has `linarith` but not `nlinarith`/`positivity`, and `simp`/`aesop` over full Mathlib found no renamed duplicate.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** `nlinarith [sq_nonneg (2*a*x+b), mul_pos ha ha] — completing the square`. Verified to build (lake env lean).
