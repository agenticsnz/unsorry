# sum-cubes-ge-sym-quadratic-two-var

For nonnegative a,b, a³+b³ ≥ a²b+ab².

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For nonnegative a,b, a³+b³ ≥ a²b+ab². Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Difference = (a+b)(a-b)² ≥ 0; supply (a+b)·(a-b)² as the nonneg certificate to nlinarith.
