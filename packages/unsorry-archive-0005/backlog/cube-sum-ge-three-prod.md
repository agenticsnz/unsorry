# cube-sum-ge-three-prod

For nonneg reals, 3abc ≤ a³+b³+c³ — AM-GM for cubes (a³+b³+c³−3abc = (a+b+c)·½Σ(a−b)²).

- **Source:** Classic elementary real inequality (#400 plan Phase 3 — library growth).
- **Reference:** For nonneg reals, 3abc ≤ a³+b³+c³ — AM-GM for cubes (a³+b³+c³−3abc = (a+b+c)·½Σ(a−b)²). Not a named mathlib lemma in this concrete polynomial/abs form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — the battery has `linarith` but not `nlinarith`/`positivity`, and `simp`/`aesop` over full Mathlib found no renamed duplicate.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** `nlinarith with sq_nonneg + mul_nonneg hints`. Verified to build (lake env lean).
