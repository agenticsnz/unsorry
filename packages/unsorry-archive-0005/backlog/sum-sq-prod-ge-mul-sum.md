# sum-sq-prod-ge-mul-sum

For all reals a,b,c, a²b²+b²c²+c²a² ≥ abc(a+b+c).

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For all reals a,b,c, a²b²+b²c²+c²a² ≥ abc(a+b+c). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** 2·LHS gap = (ab-bc)²+(bc-ca)²+(ca-ab)² ≥ 0; three product-difference squares suffice, valid for all reals.
