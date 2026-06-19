# two-sum-cubes-ge-sym-quadratics

For nonnegative a,b,c, 2(a³+b³+c³) ≥ ab(a+b)+bc(b+c)+ca(c+a).

- **Source:** #400 Identity Engine (ADR-043) — inequalities family.
- **Reference:** For nonnegative a,b,c, 2(a³+b³+c³) ≥ ab(a+b)+bc(b+c)+ca(c+a). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Pairwise a³+b³-a²b-ab² = (a+b)(a-b)² ≥ 0; sum the three pair identities, each given as (a+b)·(a-b)² hint.
