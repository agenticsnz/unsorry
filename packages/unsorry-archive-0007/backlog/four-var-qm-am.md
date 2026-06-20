# four-var-qm-am

For all real a,b,c,d, (a+b+c+d)² ≤ 4(a²+b²+c²+d²) — the 4-variable QM–AM inequality.

- **Source:** Classic elementary inequality / number-theory fact (#400 plan Phase 3).
- **Reference:** For all real a,b,c,d, (a+b+c+d)² ≤ 4(a²+b²+c²+d²) — the 4-variable QM–AM inequality. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with the 6 pairwise sq_nonneg hints. Verified to build (lake env lean).
