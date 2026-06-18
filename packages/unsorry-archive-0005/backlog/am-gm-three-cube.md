# am-gm-three-cube

For nonneg reals, 27abc ≤ (a+b+c)³ — AM-GM for three terms (polynomial form).

- **Source:** Classic elementary real inequality (#400 plan Phase 3 — library growth).
- **Reference:** For nonneg reals, 27abc ≤ (a+b+c)³ — AM-GM for three terms (polynomial form). Not a named mathlib lemma in this concrete polynomial/abs form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — the battery has `linarith` but not `nlinarith`/`positivity`, and `simp`/`aesop` over full Mathlib found no renamed duplicate.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** `nlinarith with sq_nonneg + mul_nonneg + mul_nonneg-with-sq hints`. Verified to build (lake env lean).
