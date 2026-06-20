# sum-two-k-plus-one-div-sq-succ-sq-telescope

The sum over k<n of (2(k+1)+1)/((k+1)²(k+2)²) equals 1 − 1/(n+1)².

- **Source:** #400 Identity Engine (ADR-043) — telescoping family.
- **Reference:** The sum over k<n of (2(k+1)+1)/((k+1)²(k+2)²) equals 1 − 1/(n+1)². Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; each term is 1/(k+1)² − 1/(k+2)², telescoping to 1 − 1/(n+1)²; field_simp/ring on the step.
