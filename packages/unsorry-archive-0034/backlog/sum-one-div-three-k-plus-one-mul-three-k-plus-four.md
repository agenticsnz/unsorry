# sum-one-div-three-k-plus-one-mul-three-k-plus-four

The sum over k<n of 1/((3k+1)(3k+4)) equals n/(3n+1).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family.
- **Reference:** The sum over k<n of 1/((3k+1)(3k+4)) equals n/(3n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; (1/3)(1/(3k+1) − 1/(3k+4)) telescopes to (1/3)(1 − 1/(3n+1)) = n/(3n+1); field_simp/ring on the step.
