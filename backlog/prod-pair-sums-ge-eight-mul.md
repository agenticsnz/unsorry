# prod-pair-sums-ge-eight-mul

For nonnegative a,b,c, (a+b)(b+c)(c+a) ≥ 8abc.

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For nonnegative a,b,c, (a+b)(b+c)(c+a) ≥ 8abc. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Expansion minus 8abc equals a(b-c)²+b(c-a)²+c(a-b)² ≥ 0; supply each weighted-square term as an nlinarith hint.
