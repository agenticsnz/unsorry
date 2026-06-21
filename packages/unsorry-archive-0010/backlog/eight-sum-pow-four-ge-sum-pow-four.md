# eight-sum-pow-four-ge-sum-pow-four

For all reals a,b, (a+b)⁴ ≤ 8(a⁴+b⁴).

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For all reals a,b, (a+b)⁴ ≤ 8(a⁴+b⁴). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** 8(a⁴+b⁴)-(a+b)⁴ = (a-b)²(7a²+10ab+7b²) ≥ 0 since 7a²+10ab+7b² has negative discriminant; SOS products close it.
