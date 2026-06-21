# am-hm-two-var

For positive reals a,b, 4/(a+b) ≤ 1/a + 1/b — the two-variable AM–HM inequality.

- **Source:** Classic elementary inequality / number-theory fact (#400 plan Phase 3 — library growth).
- **Reference:** For positive reals a,b, 4/(a+b) ≤ 1/a + 1/b — the two-variable AM–HM inequality. Not a named mathlib lemma in this concrete form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** clear denominators (div_add_div + div_le_div_iff₀) then nlinarith [sq_nonneg (a−b)]. Verified to build (lake env lean).
