# pow-four-add-pow-four-ge-cube-mul

For all reals a,b, a⁴+b⁴ ≥ a³b+ab³.

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For all reals a,b, a⁴+b⁴ ≥ a³b+ab³. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Difference = (a-b)²(a²+ab+b²) ≥ 0; feed nlinarith the SOS products (a-b)²·a², (a-b)²·b², (a-b)²·(a+b)².
