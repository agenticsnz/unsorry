# pow-five-add-pow-five-ge-quartic-mul

For nonnegative a,b, a⁵+b⁵ ≥ a⁴b+ab⁴.

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For nonnegative a,b, a⁵+b⁵ ≥ a⁴b+ab⁴. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Difference = (a-b)²(a+b)(a²+b²) ≥ 0; give nlinarith the product (a+b)(a²+b²)·(a-b)² as a single nonneg hint.
