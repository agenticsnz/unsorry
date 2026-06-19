# sym-deg-three-ge-six-mul

For nonnegative a,b,c, a²b+ab²+b²c+bc²+c²a+ca² ≥ 6abc.

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For nonnegative a,b,c, a²b+ab²+b²c+bc²+c²a+ca² ≥ 6abc. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** LHS−6abc = a(b-c)²+b(c-a)²+c(a-b)² ≥ 0; each weighted square is a direct mul_nonneg hint.
